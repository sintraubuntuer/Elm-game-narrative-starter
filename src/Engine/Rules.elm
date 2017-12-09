module Engine.Rules
    exposing
        ( findMatchingRule
        , bestMatch
        , chooseFrom
        )

import Types exposing (..)
import Dict exposing (Dict)
import Engine.Manifest exposing (..)


findMatchingRule : Story -> Maybe String -> String -> Maybe ( String, Rule )
findMatchingRule story mbInputText interaction =
    story.rules
        |> Dict.toList
        |> List.filter (Tuple.second >> matchesRule story mbInputText interaction)
        |> List.map
            (\( id, { interaction, conditions, changes, quasiChanges, quasiChangeWithBkend } ) ->
                { id = id, interaction = interaction, conditions = conditions, changes = changes, quasiChanges = quasiChanges, quasiChangeWithBkend = quasiChangeWithBkend }
            )
        |> bestMatch
            (numConstrictionsWeight
                +> sceneConstraintWeight
                +> specificityWeight
            )
        |> Maybe.map
            (\{ id, interaction, conditions, changes, quasiChanges, quasiChangeWithBkend } ->
                ( id, { interaction = interaction, conditions = conditions, changes = changes, quasiChanges = quasiChanges, quasiChangeWithBkend = quasiChangeWithBkend } )
            )


{-| Feed two functions the same value and add their results. Like a Reader, but adds the results of the functions instead of composing them.
-}
(+>) : (a -> Int) -> (a -> Int) -> (a -> Int)
(+>) f1 f2 a =
    f1 a + f2 a


bestMatch : (a -> Int) -> List a -> Maybe a
bestMatch heuristics matchingRules =
    List.sortBy heuristics matchingRules
        |> List.reverse
        |> List.head


numConstrictionsWeight : { a | conditions : List Condition } -> Int
numConstrictionsWeight =
    .conditions >> List.length


sceneConstraintWeight : { a | conditions : List Condition } -> Int
sceneConstraintWeight rule =
    let
        hasSceneConstraints condition =
            case condition of
                CurrentSceneIs _ ->
                    True

                _ ->
                    False
    in
        if List.any hasSceneConstraints rule.conditions then
            300
        else
            0


specificityWeight : { a | interaction : InteractionMatcher } -> Int
specificityWeight rule =
    case rule.interaction of
        With _ ->
            200

        WithAnyItem ->
            100

        WithAnyLocation ->
            100

        WithAnyCharacter ->
            100

        WithAnyLocationAnyCharacterAfterGameEnded ->
            -- game ended but player can still look at items
            100000

        WithAnythingAfterGameEnded ->
            100000

        WithAnythingHighPriority ->
            100000

        WithAnything ->
            0


chooseFrom : Story -> List { a | conditions : List Condition } -> Maybe { a | conditions : List Condition }
chooseFrom ({ currentLocation, currentScene, manifest, history } as story) =
    List.filter (.conditions >> List.all (matchesCondition story Nothing))
        >> bestMatch (numConstrictionsWeight +> sceneConstraintWeight)


matchesRule : Story -> Maybe String -> String -> Rule -> Bool
matchesRule ({ currentLocation, currentScene, manifest, history } as story) mbInputText interaction rule =
    matchesInteraction manifest rule.interaction interaction
        && List.all (matchesCondition story mbInputText) rule.conditions


matchesInteraction :
    Manifest
    -> InteractionMatcher
    -> String
    -> Bool
matchesInteraction manifest interactionMatcher interactableId =
    case interactionMatcher of
        WithAnything ->
            True

        WithAnyItem ->
            isItem interactableId manifest

        WithAnyLocation ->
            isLocation interactableId manifest

        WithAnyCharacter ->
            isCharacter interactableId manifest

        WithAnyLocationAnyCharacterAfterGameEnded ->
            (isLocation interactableId manifest)
                || (isCharacter interactableId manifest)

        WithAnythingAfterGameEnded ->
            True

        WithAnythingHighPriority ->
            True

        With id ->
            id == interactableId


matchesCondition :
    Story
    -> Maybe String
    -> Condition
    -> Bool
matchesCondition { history, currentLocation, currentScene, manifest } mbInputText condition =
    case condition of
        ItemIsInInventory item ->
            itemIsInInventory item manifest

        CharacterIsInLocation character location ->
            characterIsInLocation character location manifest

        ItemIsInLocation item location ->
            itemIsInLocation item location manifest

        CurrentLocationIs location ->
            currentLocation == location

        ItemIsNotInInventory item ->
            not <| itemIsInInventory item manifest

        CharacterIsNotInLocation character location ->
            not <| characterIsInLocation character location manifest

        ItemIsNotInLocation item location ->
            not <| itemIsInLocation item location manifest

        ItemIsOffScreen item ->
            itemIsOffScreen item manifest

        ItemIsInAnyLocationOrInventory item ->
            itemIsInAnyLocationOrInventory item manifest

        ItemIsCorrectlyAnswered item ->
            itemIsCorrectlyAnswered item manifest

        ItemIsNotCorrectlyAnswered item ->
            itemIsNotCorrectlyAnswered item manifest

        CurrentLocationIsNot location ->
            not <| currentLocation == location

        HasPreviouslyInteractedWith id ->
            List.map Tuple.first history
                |> List.member id

        HasNotPreviouslyInteractedWith id ->
            List.map Tuple.first history
                |> List.member id
                |> not

        CurrentSceneIs id ->
            currentScene == id

        CounterExists counterId interId ->
            counterExists counterId interId manifest

        CounterLessThen val counterId interId ->
            counterLessThen val counterId interId manifest

        CounterGreaterThenOrEqualTo val counterId interId ->
            counterGreaterThenOrEqualTo val counterId interId manifest

        AttrValueIsEqualTo val attrId interId ->
            attrValueIsEqualTo val attrId interId manifest

        ChosenOptionIsEqualTo valueToMatch interId ->
            chosenOptionIsEqualTo valueToMatch mbInputText

        NoChosenOptionYet interactableId ->
            noChosenOptionYet interactableId manifest

        ChoiceHasAlreadyBeenMade interactableId ->
            choiceHasAlreadyBeenMade interactableId manifest
