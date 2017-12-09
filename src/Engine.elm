module Engine
    exposing
        ( Model
        , init
        , update
        , changeWorld
        , chooseFrom
        , getCurrentScene
        , getCurrentLocation
        , getChoiceLanguages
        , getItemsInCurrentLocation
        , getCharactersInCurrentLocation
        , getItemsInInventory
        , getItemWrittenContent
        , getInteractableAttribute
        , check_IfAnswerCorrect
        , simpleCheck_IfAnswerCorrect
        , simpleCheck_IfAnswerCorrectUsingBackend
        , checkAndAct_IfChosenOptionIs
        , check_IfAnswerCorrectUsingBackend
        , processChosenOptionEqualTo
        , createCounterIfNotExists
        , createAttributeIfNotExists
        , createAttributeIfNotExistsAndOrSetValue
        , createOrSetAttributeValueFromOtherInterAttr
        , createAmultiChoice
        , removeMultiChoiceOptions
        , setAttributeValue
        , removeAttributeIfExists
        , increaseCounter
        , getLocations
        , getEndingText
        , getHistory
        , getStoryRules
        , hasFreezingEnd
        , hasEnded
        , GeolocationInfo
        , EndingType
        , Rules
        , Rule
        , Rule_
        , InteractionMatcher
        , with
        , withAnything
        , withAnyItem
        , withAnyLocation
        , withAnyCharacter
        , withAnyLocationAnyCharacterAfterGameEnded
        , withAnythingAfterGameEnded
        , withAnythingHighPriority
        , Condition
        , characterIsNotInLocation
        , characterIsInLocation
        , currentLocationIs
        , currentLocationIsNot
        , itemIsInInventory
        , itemIsNotInInventory
        , itemIsNotInLocation
        , itemIsInLocation
        , itemIsOffScreen
        , itemIsInAnyLocationOrInventory
        , areThereWritableItemsInLocation
        , itemIsCorrectlyAnswered
          -- this returns a condition
        , isItemCorrectlyAnswered
          -- this returns a bool
        , itemIsNotCorrectlyAnswered
        , isWritable
        , hasPreviouslyInteractedWith
        , hasNotPreviouslyInteractedWith
        , currentSceneIs
        , counterExists
        , counterLessThen
        , counterGreaterThenOrEqualTo
        , attrValueIsEqualTo
        , attrBValueIsEqualTo
        , chosenOptionIsEqualTo
        , noChosenOptionYet
        , choiceHasAlreadyBeenMade
        , ChangeWorldCommand
        , QuasiChangeWorldCommand
        , QuasiChangeWorldCommandWithBackendInfo
        , addLocation
        , endStory
        , loadScene
        , moveCharacterToLocation
        , moveCharacterOffScreen
        , moveItemToLocation
        , moveItemToLocationFixed
        , moveItemOffScreen
        , moveItemToInventory
        , makeItemWritable
        , makeItemUnwritable
        , writeTextToItem
        , write_InputTextToItem
        , writeForceTextToItemFromGivenItemAttr
        , write_GpsInfoToItem
        , clearWrittenText
        , moveTo
        , removeLocation
        , checkAnswerData
        , checkBkendAnswerData
        , checkOptionData
        , addChoiceLanguage
        , astring
        , aliststring
        , aliststringstring
        , anint
        , abool
        , aDictStringString
        , aDictStringLSS
        , completeTheRule
        , caseSensitiveAnswer
        , caseInsensitiveAnswer
        , answerSpacesMatter
        , answerSpacesDontMatter
        , headerAnswerAndCorrectIncorrect
        , noFeedback
        , noQuasiChange
        , noQuasiChangeWithBackend
        )

{-| The story engine handles storing and advancing the state of the "world model" by running through your story rules on each interaction and updating the world model appropriately. It is designed to be embedded in your own Elm app, allowing for maximum flexibility and customization.

You can base your app on the [interactive story starter repo](https://github.com/jschomay/elm-interactive-story-starter.git).

@docs Model


## Embedding the engine

@docs init, changeWorld, chooseFrom


## Accessors

The engine exposes many accessor functions for each part of the story world. Note that each of these only return ids. It is up to the client to map an id to the appropriate associated display content. It is useful to follow an "Entity Component System" pattern in the client for this purpose (see the story starter).

@docs getCurrentScene, getCurrentLocation, getItemsInCurrentLocation, getCharactersInCurrentLocation, getItemsInInventory, getLocations, getEndingText


## Story rules

Rules are how you progress the story. They are made up of conditions to match against and commands to perform if the rule matches. On each call of `update`, the engine will run through all of the rules to find the best match. If no rules match, the framework will perform a default command, which is usually just to narrate the description of what was interacted with, or to move you to that location or take that item. If multiple rules match the current state of the world, the "best" choice will be selected based on the following weighting criteria:

1.  a `currentSceneIs` condition has the highest weight
2.  `with` has more weight than the broader `withAny*` matchers
3.  each additional condition adds more weight

In the case of a tie, the first candidate will be chosen, which is something you want to avoid, so design your rules carefully


# Anatomy of a rule

1.  A matcher against what interactable story element id the user clicked on

2.  A list of conditions that all must match for the rule to match

3.  A list of changes to make if the rule matches

         rules =
            [ { interaction = with "River"
              , conditions =
                   [ currentLocationIs "Cottage"
                   , itemIsInInventory "Cape"
                   , itemIsInInventory "Basket of food"
                   ]
              , changes =
                   [ moveTo "River"
                   , moveCharacterToLocation "Little Red Riding Hood" "River"
                   ]
              }
           -- etc
           ]

@docs Rule, Rules, update


### Interaction matchers

The following interaction matchers can be used in the `interaction` part of the rule record.

@docs InteractionMatcher, with, withAnything, withAnyItem, withAnyLocation, withAnyCharacter


### Conditions

The following condition matchers can be used in the `conditions` part of the rule record.

@docs Condition, itemIsInInventory , characterIsInLocation , itemIsInLocation , currentLocationIs, itemIsNotInInventory , hasPreviouslyInteractedWith, hasNotPreviouslyInteractedWith, currentSceneIs, characterIsNotInLocation , itemIsNotInLocation , currentLocationIsNot


### Changing the story world

You cannot change the story directly, but you can supply "commands" describing how the story state should change.

@docs ChangeWorldCommand, moveTo, addLocation, removeLocation, moveItemToInventory, moveCharacterToLocation, moveCharacterOffScreen, moveItemToLocation, moveItemToLocationFixed, moveItemOffScreen, loadScene, endStory

-}

import Types exposing (..)
import Engine.Manifest exposing (..)
import Engine.Rules exposing (..)
import Dict exposing (Dict)


type alias GeolocationInfo =
    Types.GeolocationInfo


type alias EndingType =
    Types.EndingType


{-| The opaque type that holds all of the "world model" state, such as where each item and character is, what the current location and scene are, etc.
-}
type Model
    = Model Types.Story


{-| Initialize the `Model` for use when embedding in your own app. Provide your "manifest" (a list of ids) of all of the items, characters, and locations in your story,
a list of languages the user can choose from ( this might chage , be increased along the story)
and the rules that govern the story.
You will most likely want to call `changeWorld` immediately after `init` to setup your initial story state (the current scene, location, and any initial placements of items or characters and known locations).
-}
init :
    { items : List String
    , locations : List String
    , characters : List String
    }
    -> Dict.Dict String String
    -> Rules
    -> Model
init manifest llanguages rules =
    Model
        { history = []
        , manifest = Engine.Manifest.init manifest
        , rules = rules
        , currentScene = ""
        , currentLocation = ""
        , choiceLanguages = llanguages
        , theEnd = Nothing
        }


{-| This gets the current scene to display
-}
getCurrentScene : Model -> String
getCurrentScene (Model story) =
    story.currentScene


{-| Get the current location to display
-}
getCurrentLocation : Model -> String
getCurrentLocation (Model story) =
    story.currentLocation


getChoiceLanguages : Model -> Dict.Dict String String
getChoiceLanguages (Model story) =
    story.choiceLanguages


{-| Get a list of the items in the current location to display
-}
getItemsInCurrentLocation : Model -> List String
getItemsInCurrentLocation (Model story) =
    Engine.Manifest.getItemsInLocation story.currentLocation story.manifest


areThereWritableItemsInLocation : Model -> Bool
areThereWritableItemsInLocation (Model story) =
    if (Engine.Manifest.countWritableItemsInLocation story.currentLocation story.manifest > 0) then
        True
    else
        False


{-| Get a list of the characters in the current location to display
-}
getCharactersInCurrentLocation : Model -> List String
getCharactersInCurrentLocation (Model story) =
    Engine.Manifest.getCharactersInLocation story.currentLocation story.manifest


{-| Get a list of the items in your inventory to display
-}
getItemsInInventory : Model -> List String
getItemsInInventory (Model story) =
    Engine.Manifest.getItemsInInventory story.manifest


getItemWrittenContent : String -> Model -> Maybe String
getItemWrittenContent id (Model story) =
    let
        theManifest =
            story.manifest

        mbinteractable =
            Dict.get id theManifest
    in
        Engine.Manifest.getItemWrittenContent mbinteractable


getInteractableAttribute : String -> String -> Model -> Maybe AttrTypes
getInteractableAttribute attrId interactableId (Model story) =
    story.manifest
        |> Dict.get interactableId
        |> Engine.Manifest.getInteractableAttribute attrId


isWritable : String -> Model -> Bool
isWritable interactableId (Model story) =
    Engine.Manifest.isWritable interactableId story.manifest


{-| Get a list of the known locations to display
-}
getLocations : Model -> List String
getLocations (Model story) =
    Engine.Manifest.getLocations story.manifest


{-| Get the story ending, if it has ended. (Set with `EndStory`)
-}
getEndingText : Model -> Maybe String
getEndingText (Model story) =
    case story.theEnd of
        Nothing ->
            Nothing

        Just anEnd ->
            case anEnd of
                TheEnd t mbs ->
                    Just mbs


hasFreezingEnd : Model -> Bool
hasFreezingEnd (Model story) =
    case story.theEnd of
        Nothing ->
            False

        Just anEnd ->
            case anEnd of
                TheEnd FreezingEnd mbs ->
                    True

                _ ->
                    False


hasEnded : Model -> Bool
hasEnded (Model story) =
    case story.theEnd of
        Nothing ->
            False

        Just anEnd ->
            True


isItemCorrectlyAnswered : String -> Model -> Bool
isItemCorrectlyAnswered id (Model story) =
    Engine.Manifest.itemIsCorrectlyAnswered id story.manifest


getHistory : Model -> List ( String, InteractionExtraInfo )
getHistory (Model story) =
    story.history


getStoryRules : Model -> Dict String Rule
getStoryRules (Model story) =
    story.rules


{-| This is how you progress the story. Call it with the id of what ever was just "interacted" with. This will apply the best matching rule for the current context, or if it does not find a matching rule, it will perform some sensible default changes such as adding an item to inventory or moving to a location if no rules match. It also adds the interaction to the history (which is used for `hasPreviouslyInteractedWith`, save/load, and undo).

This will also return the id of the matching rule (if there was one). Normally the client would look up some associated narrative by this id to display, though it could respond in any other way as well.

-}
update :
    String
    -> Types.InteractionExtraInfo
    -> Model
    -> ( Model, Maybe String, List String, Types.MoreInfoNeeded )
update interactableId extraInfo ((Model story) as model) =
    let
        defaultChanges : List ChangeWorldCommand
        defaultChanges =
            if Engine.Manifest.isLocation interactableId story.manifest then
                [ MoveTo interactableId ]
            else if Engine.Manifest.isItem interactableId story.manifest then
                [ MoveItemToInventory interactableId ]
            else
                []

        matchingRule : Maybe ( String, Rule )
        matchingRule =
            case extraInfo.mbMatchedRuleId of
                Nothing ->
                    findMatchingRule story extraInfo.mbInputText interactableId

                Just matchedRuleId ->
                    -- this means that we are just completing a command that was not possible to complete prior to having some backend info
                    -- we already know what rule matched and we dont want to search it again because it is also possible that in the meantime  the player interacted with something else and altered the conditions
                    Maybe.map (\x -> ( matchedRuleId, x )) (Dict.get matchedRuleId story.rules)

        somechanges : List ChangeWorldCommand
        somechanges =
            matchingRule
                |> Maybe.map (Tuple.second >> .changes)
                |> Maybe.withDefault defaultChanges

        lquasicwcmds : List QuasiChangeWorldCommand
        lquasicwcmds =
            matchingRule
                |> Maybe.map (Tuple.second >> .quasiChanges)
                |> Maybe.withDefault []

        mbBkQuasicwcmd : Maybe QuasiChangeWorldCommandWithBackendInfo
        mbBkQuasicwcmd =
            matchingRule
                |> Maybe.map (Tuple.second >> .quasiChangeWithBkend)

        infoNeeded : MoreInfoNeeded
        infoNeeded =
            -- if there are Check_IfAnswerCorrectUsingBackend get the InfoNeeded strUrl to request answer info from backend
            case mbBkQuasicwcmd of
                Nothing ->
                    NoInfoNeeded

                Just quasicwcmd ->
                    getInfoNeeded quasicwcmd

        mbChangeFromQuasi : Maybe ChangeWorldCommand
        mbChangeFromQuasi =
            Maybe.map (replaceBkendQuasiCwCmdsWithCwcommands extraInfo) mbBkQuasicwcmd

        changesFromQuasi : List ChangeWorldCommand
        changesFromQuasi =
            lquasicwcmds
                |> List.map (replaceQuasiCwCmdsWithCwcommands extraInfo)

        changes : List ChangeWorldCommand
        changes =
            case mbChangeFromQuasi of
                Nothing ->
                    somechanges ++ changesFromQuasi

                Just chg ->
                    chg :: (somechanges ++ changesFromQuasi)

        addHistory : Model -> Model
        addHistory (Model story) =
            Model <| { story | history = story.history ++ [ ( interactableId, extraInfo ) ] }
    in
        if (infoNeeded /= NoInfoNeeded && extraInfo.bkAnsStatus == NoInfoYet && extraInfo.mbInputTextForBackend /= Nothing && (extraInfo.mbInputTextForBackend /= Just "")) then
            ( model, Maybe.map Tuple.first matchingRule, [], infoNeeded )
        else if (infoNeeded /= NoInfoNeeded && extraInfo.bkAnsStatus == WaitingForInfoRequested) then
            ( model, Maybe.map Tuple.first matchingRule, [], NoInfoNeeded )
        else
            let
                ( newModel, lincidents ) =
                    changeWorld changes model
            in
                ( newModel |> addHistory
                , Maybe.map Tuple.first matchingRule
                , lincidents
                , NoInfoNeeded
                )


getInfoNeeded : QuasiChangeWorldCommandWithBackendInfo -> MoreInfoNeeded
getInfoNeeded qcwcommand =
    case qcwcommand of
        Check_IfAnswerCorrectUsingBackend strUrl cAnsdata id ->
            AnswerInfoToQuestionNeeded strUrl

        _ ->
            NoInfoNeeded


replaceBkendQuasiCwCmdsWithCwcommands : Types.InteractionExtraInfo -> QuasiChangeWorldCommandWithBackendInfo -> ChangeWorldCommand
replaceBkendQuasiCwCmdsWithCwcommands extraInfo quasiBkendCwCommand =
    case quasiBkendCwCommand of
        NoQuasiChangeWithBackend ->
            NoChange

        Check_IfAnswerCorrectUsingBackend strUrl cAnswerData interactableId ->
            replaceCheckIfAnswerCorrectUsingBackend extraInfo.bkAnsStatus strUrl cAnswerData interactableId


replaceQuasiCwCmdsWithCwcommands : Types.InteractionExtraInfo -> QuasiChangeWorldCommand -> ChangeWorldCommand
replaceQuasiCwCmdsWithCwcommands extraInfo quasiCwCommand =
    case quasiCwCommand of
        NoQuasiChange ->
            NoChange

        Check_IfAnswerCorrect theCorrectAnswers cAnswerData interactableId ->
            replaceCheckIfAnswerCorrect extraInfo.mbInputText theCorrectAnswers cAnswerData interactableId

        CheckAndAct_IfChosenOptionIs cOptionData itemid ->
            replaceCheckAndActIfChosenOptionIs extraInfo.mbInputText cOptionData itemid

        Write_InputTextToItem interactableId ->
            replaceWriteInputTextToItem extraInfo.mbInputText interactableId

        Write_GpsInfoToItem interactableId ->
            replaceWriteGpsInfoToItem extraInfo.geolocationInfoText interactableId


replaceCheckIfAnswerCorrectUsingBackend : BackendAnswerStatus -> String -> CheckBkendAnswerData -> String -> ChangeWorldCommand
replaceCheckIfAnswerCorrectUsingBackend bkendAnsStatus strUrl cAnswerData interactableId =
    case bkendAnsStatus of
        -- no change yet . . Needs to request info from backend
        NoInfoYet ->
            NoChange

        -- info has already been requested ,  we dont want to request it again
        WaitingForInfoRequested ->
            NoChange

        Ans answerinfo ->
            let
                checkAnswerData =
                    (CheckAnswerData
                        cAnswerData.mbMaxNrTries
                        CaseInsensitiveAnswer
                        AnswerSpacesDontMatter
                        cAnswerData.answerFeedback
                        (Dict.fromList <| List.map (\x -> ( x.lgId, x.text )) answerinfo.successTextList)
                        (Dict.fromList <| List.map (\x -> ( x.lgId, x.text )) answerinfo.insuccessTextList)
                        cAnswerData.lnewAttrs
                        cAnswerData.lotherInterAttrs
                    )

                newCheckAnswerDataIfSuccess =
                    { checkAnswerData | lnewAttrs = cAnswerData.lnewAttrs ++ [ ( "bonusText", ADictStringString (List.map (\x -> ( x.lgId, x.text )) answerinfo.secretTextList |> Dict.fromList) ) ] }

                newCheckAnswerDataIfInsuccess =
                    checkAnswerData
            in
                if (answerinfo.maxTriesReached) then
                    WriteTextToItem
                        ("  \n"
                            ++ " "
                            ++ " ___MAX_TRIES_ON_BACKEND___ "
                            ++ " ,  "
                            ++ "  \n , "
                            ++ " ___YOUR_ANSWER___ "
                            ++ " "
                            ++ (answerinfo.playerAnswer)
                        )
                        interactableId
                else if (answerinfo.answered && answerinfo.correctAnswer) then
                    CheckIfAnswerCorrect ([ answerinfo.playerAnswer ]) (answerinfo.playerAnswer) newCheckAnswerDataIfSuccess interactableId
                else if (answerinfo.answered && answerinfo.incorrectAnswer) then
                    CheckIfAnswerCorrect ([ answerinfo.playerAnswer ++ "something" ]) answerinfo.playerAnswer newCheckAnswerDataIfInsuccess interactableId
                else
                    -- ( not answerinfo.answered )
                    NoChange

        CommunicationFailure ->
            WriteTextToItem
                ("  \n" ++ " " ++ "___Couldnt_check_Answer___")
                interactableId


replaceCheckIfAnswerCorrect : Maybe String -> List String -> CheckAnswerData -> String -> ChangeWorldCommand
replaceCheckIfAnswerCorrect mbInputText theCorrectAnswers cAnswerData interactableId =
    if (mbInputText /= Nothing && mbInputText /= (Just "")) then
        let
            playerAnswer =
                Maybe.withDefault "" mbInputText
        in
            CheckIfAnswerCorrect theCorrectAnswers playerAnswer cAnswerData interactableId
    else
        NoChange


replaceCheckAndActIfChosenOptionIs : Maybe String -> CheckOptionData -> String -> ChangeWorldCommand
replaceCheckAndActIfChosenOptionIs mbInputText cOptionData itemid =
    let
        playerChoice =
            Maybe.withDefault "" mbInputText
    in
        CheckAndActIfChosenOptionIs playerChoice cOptionData itemid


{-| used to replace the Write_TextToItem QuasiChangeWorldCommand coming from the configuration rules file
and substitute with WriteInputTextToItem by adding the
extra parameter Maybe InputText ( text typed by the user ) it got from Main.elm
-}
replaceWriteInputTextToItem : Maybe String -> String -> ChangeWorldCommand
replaceWriteInputTextToItem mbText id =
    WriteTextToItem (Maybe.withDefault "" mbText) id


{-| used to replace the Write_GpsInfo QuasiChangeWorldCommand coming from the configuration rules file
and substitute with WriteGpsLocInfoToItem by adding the
extra parameter Maybe GeolocationInfo it got from Main.elm
-}
replaceWriteGpsInfoToItem : String -> String -> ChangeWorldCommand
replaceWriteGpsInfoToItem geolocationInfoText id =
    WriteGpsLocInfoToItem geolocationInfoText id


{-| A way to change the story world directly, rather than responding to a player's interaction.

For example, you could change the current location in the story based on browser geolocation events, or respond to a network event, etc. This is also used to set up any initial story state.

If you are simply responding to a player's interaction, use `update` instead.

-}
changeWorld :
    List ChangeWorldCommand
    -> Model
    -> ( Model, List String )
changeWorld changes (Model story) =
    let
        doChange change ( story, linteractionIncidents ) =
            case change of
                MoveTo location ->
                    ( { story | currentLocation = location }, linteractionIncidents )

                LoadScene sceneName ->
                    ( { story | currentScene = sceneName }, linteractionIncidents )

                EndStory endingtype ending ->
                    ( { story | theEnd = Just (TheEnd endingtype ending) }, linteractionIncidents )

                SetChoiceLanguages dictLgs ->
                    ( { story | choiceLanguages = dictLgs }, linteractionIncidents )

                AddChoiceLanguage lgId lgName ->
                    -- used to allow the increase of available languages during the narrative
                    ( { story | choiceLanguages = Dict.insert lgId lgName story.choiceLanguages }, linteractionIncidents )

                _ ->
                    let
                        ( newManifest, newIncidents ) =
                            Engine.Manifest.update change ( story.manifest, linteractionIncidents )
                    in
                        ( { story | manifest = newManifest }, newIncidents )
    in
        List.foldr (\chg y -> doChange chg y) ( story, [] ) changes
            |> (\( x, y ) -> ( Model x, y ))


{-| Given a list of choices, this will return only the choice that matches the associated conditions, if any. Useful for conditional descriptions, for example, where an item has a different description depending on where it is.

This uses the same weighting scale as the rules (below), and likewise will return the first match if there is a tie, so specify your conditions carefully.

-}
chooseFrom : Model -> List { a | conditions : List Condition } -> Maybe { a | conditions : List Condition }
chooseFrom (Model story) choices =
    Engine.Rules.chooseFrom story choices


{-| A declarative rule, describing how to advance your story and under what conditions.
-}
type alias Rule =
    Types.Rule


type alias Rules =
    Types.Rules


type alias Rule_ =
    Types.Rule_


{-| -}
type alias InteractionMatcher =
    Types.InteractionMatcher


type alias CheckAnswerData =
    Types.CheckAnswerData


type alias CheckOptionData =
    Types.CheckOptionData


{-| Will only match the `interaction` part of a story rule if the player interacted with the specified entity id.
-}
with : String -> InteractionMatcher
with id =
    With id


{-| Will match the `interaction` part of a story rule if the player interacted with any item (be careful about the conditions of your rules since this matcher is so broad).
-}
withAnyItem : InteractionMatcher
withAnyItem =
    WithAnyItem


{-| Will match the `interaction` part of a story rule if the player interacted with any location (be careful about the conditions of your rules since this matcher is so broad).
-}
withAnyLocation : InteractionMatcher
withAnyLocation =
    WithAnyLocation


{-| Will match the `interaction` part of a story rule if the player interacted with any character (be careful about the conditions of your rules since this matcher is so broad).
-}
withAnyCharacter : InteractionMatcher
withAnyCharacter =
    WithAnyCharacter


{-| Used when game ends if we still want to give the player the option to look at his items
-}
withAnyLocationAnyCharacterAfterGameEnded : InteractionMatcher
withAnyLocationAnyCharacterAfterGameEnded =
    WithAnyLocationAnyCharacterAfterGameEnded


{-| similar to withAnything but with a very high specificityWeight
so that the rule with this interaction matcher is always the best match over any other
-}
withAnythingAfterGameEnded : InteractionMatcher
withAnythingAfterGameEnded =
    WithAnythingAfterGameEnded


{-| similar to withAnything but with a very high specificityWeight
so that the rule with this interaction matcher is always the best match over any other
-}
withAnythingHighPriority : InteractionMatcher
withAnythingHighPriority =
    WithAnythingHighPriority


{-| Will match the `interaction` part of a story rule every time (be careful about the conditions of your rules since this matcher is so broad).
-}
withAnything : InteractionMatcher
withAnything =
    WithAnything


{-| -}
type alias Condition =
    Types.Condition


{-| Will only match if the supplied item is in the inventory.
-}
itemIsInInventory : String -> Condition
itemIsInInventory =
    ItemIsInInventory


{-| Will only match if the supplied item is *not* in the inventory.
-}
itemIsNotInInventory : String -> Condition
itemIsNotInInventory =
    ItemIsNotInInventory


{-| Will only match if the supplied character is in the supplied location.

The first String is a character id, the second is a location id.

-}
characterIsInLocation : String -> String -> Condition
characterIsInLocation =
    CharacterIsInLocation


{-| Will only match if the supplied interactable has already been interacted with.
-}
hasPreviouslyInteractedWith : String -> Condition
hasPreviouslyInteractedWith =
    HasPreviouslyInteractedWith


{-| Will only match if the supplied interactable has not already been interacted with.
-}
hasNotPreviouslyInteractedWith : String -> Condition
hasNotPreviouslyInteractedWith =
    HasNotPreviouslyInteractedWith


{-| Will only match if the supplied character is *not* in the supplied location.

The first String is a character id, the second is a location id.

-}
characterIsNotInLocation : String -> String -> Condition
characterIsNotInLocation =
    CharacterIsNotInLocation


{-| Will only match if the supplied item is in the supplied location.

The first String is a item id, the second is a location id.

-}
itemIsInLocation : String -> String -> Condition
itemIsInLocation =
    ItemIsInLocation


{-| Will only match if the supplied item is *not* in the supplied location.

The first String is a item id, the second is a location id.

-}
itemIsNotInLocation : String -> String -> Condition
itemIsNotInLocation =
    ItemIsNotInLocation


{-| Will only match if the supplied item is offScreen , ( or is not an interactable or an item)
The first String is a item id, the second is a location id.
-}
itemIsOffScreen : String -> Condition
itemIsOffScreen =
    ItemIsOffScreen


{-| Will only match if the supplied item is in any location , in Inventory
, ( or is not an interactable or an item)
The arg String is a item id
-}
itemIsInAnyLocationOrInventory : String -> Condition
itemIsInAnyLocationOrInventory =
    ItemIsInAnyLocationOrInventory


{-| Will only match if a given question was answered correctly
-}
itemIsCorrectlyAnswered : String -> Condition
itemIsCorrectlyAnswered =
    ItemIsCorrectlyAnswered


itemIsNotCorrectlyAnswered : String -> Condition
itemIsNotCorrectlyAnswered =
    ItemIsNotCorrectlyAnswered


attrValueIsEqualTo : AttrTypes -> String -> String -> Condition
attrValueIsEqualTo =
    AttrValueIsEqualTo


attrBValueIsEqualTo : Bool -> String -> String -> Condition
attrBValueIsEqualTo bval =
    AttrValueIsEqualTo (Abool bval)


{-| Will only match when the supplied location is the current location.
-}
currentLocationIs : String -> Condition
currentLocationIs =
    CurrentLocationIs


{-| Will only match when the supplied location is *not* the current location.
-}
currentLocationIsNot : String -> Condition
currentLocationIsNot =
    CurrentLocationIsNot


{-| Will only match when the supplied location is *not* the current location.
-}
currentSceneIs : String -> Condition
currentSceneIs =
    CurrentSceneIs


{-| Will only match when counter with Id counterId exists in interactable with Id interactableId
-}
counterExists : String -> String -> Condition
counterExists =
    CounterExists


{-| Will only match when counter with Id counterId exists
and its value is less then val in interactable with Id interactableId
-}
counterLessThen : Int -> String -> String -> Condition
counterLessThen =
    CounterLessThen


{-| Will only match when counter with Id counterId exists
and its value is greater then or equal to val in interactable with Id interactableId
-}
counterGreaterThenOrEqualTo : Int -> String -> String -> Condition
counterGreaterThenOrEqualTo =
    CounterGreaterThenOrEqualTo


chosenOptionIsEqualTo : String -> String -> Condition
chosenOptionIsEqualTo =
    ChosenOptionIsEqualTo


noChosenOptionYet : String -> Condition
noChosenOptionYet =
    NoChosenOptionYet


choiceHasAlreadyBeenMade : String -> Condition
choiceHasAlreadyBeenMade =
    ChoiceHasAlreadyBeenMade


createAmultiChoice : Dict String (List ( String, String )) -> String -> ChangeWorldCommand
createAmultiChoice =
    CreateAMultiChoice


removeMultiChoiceOptions : String -> ChangeWorldCommand
removeMultiChoiceOptions =
    RemoveMultiChoiceOptions


{-| -}
type alias ChangeWorldCommand =
    Types.ChangeWorldCommand


type alias QuasiChangeWorldCommand =
    Types.QuasiChangeWorldCommand


type alias QuasiChangeWorldCommandWithBackendInfo =
    Types.QuasiChangeWorldCommandWithBackendInfo


{-| Changes the current location.
-}
moveTo : String -> ChangeWorldCommand
moveTo =
    MoveTo


{-| Adds a location to your list of known locations. Any location on this list is available for the player to click on at any time. This avoids clunky spatial navigation mechanics, but does mean that you will need to make rules to prevent against going to locations that are inaccessible (with appropriate narration).
-}
addLocation : String -> ChangeWorldCommand
addLocation =
    AddLocation


{-| Removes a location from your list of known locations. You probably don't need this since once you know about a location you would always know about it, and trying to go to a location that is inaccessible for some reason could just give some narration telling why. But maybe you will find a good reason to use it.
-}
removeLocation : String -> ChangeWorldCommand
removeLocation =
    RemoveLocation


{-| Adds an item to your inventory (if it was previously in a location, it will be removed from there, as items can only be in one place at once). If the item is "fixed" this will not move it (if you want to "unfix" an item, use `moveItemOffScreen` or `MoveItemToLocation` first).
-}
moveItemToInventory : String -> ChangeWorldCommand
moveItemToInventory =
    MoveItemToInventory


{-| Makes an item writable by 'setting' its IsWritable to True
-}
makeItemWritable : String -> ChangeWorldCommand
makeItemWritable =
    MakeItemWritable


{-| Makes an item unwritable by 'setting' its IsWritable to False
-}
makeItemUnwritable : String -> ChangeWorldCommand
makeItemUnwritable =
    MakeItemUnwritable


{-| Tries to Write text to an item . If item is writable its writtenContent will be 'altered'
-}
writeTextToItem : String -> String -> ChangeWorldCommand
writeTextToItem =
    WriteTextToItem


write_InputTextToItem : String -> QuasiChangeWorldCommand
write_InputTextToItem =
    Write_InputTextToItem


clearWrittenText : String -> ChangeWorldCommand
clearWrittenText =
    ClearWrittenText


{-| Tries to Write Text to an Item from the value of an attribute on given ( other or same ) interactable id
first arg : AttributeId , second arg : given interactable id , third arg : interactableid we want to write on
-}
writeForceTextToItemFromGivenItemAttr : String -> String -> String -> ChangeWorldCommand
writeForceTextToItemFromGivenItemAttr =
    WriteForceTextToItemFromGivenItemAttr


write_GpsInfoToItem : String -> QuasiChangeWorldCommand
write_GpsInfoToItem =
    Write_GpsInfoToItem


{-| function that comes from the Rules config and is gonna be replaced by CheckIfAnswerCorrect in Engine.update
after it is replaced by CheckIfAnswerCorrect it will be processed by the respective function in Engine.Manifest which
Checks if player answer is
contained in given list string = allowed right answers ( first arg )
-}
check_IfAnswerCorrect : List String -> CheckAnswerData -> String -> QuasiChangeWorldCommand
check_IfAnswerCorrect =
    Check_IfAnswerCorrect


simpleCheck_IfAnswerCorrect : List String -> Maybe Int -> String -> QuasiChangeWorldCommand
simpleCheck_IfAnswerCorrect lcorrectAnswers mbNrTries interactableId =
    Check_IfAnswerCorrect lcorrectAnswers (CheckAnswerData mbNrTries CaseInsensitiveAnswer AnswerSpacesDontMatter HeaderAnswerAndCorrectIncorrect Dict.empty Dict.empty [] []) interactableId


check_IfAnswerCorrectUsingBackend : String -> CheckBkendAnswerData -> String -> QuasiChangeWorldCommandWithBackendInfo
check_IfAnswerCorrectUsingBackend =
    Check_IfAnswerCorrectUsingBackend


simpleCheck_IfAnswerCorrectUsingBackend : String -> Maybe Int -> String -> QuasiChangeWorldCommandWithBackendInfo
simpleCheck_IfAnswerCorrectUsingBackend strUrl mbNrTries interactableId =
    Check_IfAnswerCorrectUsingBackend strUrl (CheckBkendAnswerData mbNrTries HeaderAnswerAndCorrectIncorrect [] []) interactableId


checkAndAct_IfChosenOptionIs : CheckOptionData -> String -> QuasiChangeWorldCommand
checkAndAct_IfChosenOptionIs =
    CheckAndAct_IfChosenOptionIs


processChosenOptionEqualTo : CheckOptionData -> String -> ChangeWorldCommand
processChosenOptionEqualTo =
    ProcessChosenOptionEqualTo


{-| creates an attribute with name ("counter_" ++ Id) with Id passed as first arg , in interactable with Id : String second arg
-}
createCounterIfNotExists : String -> String -> ChangeWorldCommand
createCounterIfNotExists =
    CreateCounterIfNotExists


{-| increases counter with nameId : String first arg , in interactable with Id : String second arg
-}
increaseCounter : String -> String -> ChangeWorldCommand
increaseCounter =
    IncreaseCounter


createAttributeIfNotExists : AttrTypes -> String -> String -> ChangeWorldCommand
createAttributeIfNotExists val attrId interactableId =
    let
        reservedAttrIds =
            Engine.Manifest.getReservedAttrIds
    in
        if (not (List.member attrId reservedAttrIds)) then
            CreateAttributeIfNotExists val attrId interactableId
        else
            let
                _ =
                    Debug.log "Sorry ! It was not possible to create attribute. That's a 'reserved' attributeId : " attrId
            in
                NoChange


createAttributeIfNotExistsAndOrSetValue : AttrTypes -> String -> String -> ChangeWorldCommand
createAttributeIfNotExistsAndOrSetValue val attrId interactableId =
    let
        reservedAttrIds =
            Engine.Manifest.getReservedAttrIds
    in
        if (not (List.member attrId reservedAttrIds)) then
            CreateAttributeIfNotExistsAndOrSetValue val attrId interactableId
        else
            let
                _ =
                    Debug.log "Sorry ! It was not possible to create or set attribute. That's a 'reserved' attributeId : " attrId
            in
                NoChange


createOrSetAttributeValueFromOtherInterAttr : String -> String -> String -> String -> ChangeWorldCommand
createOrSetAttributeValueFromOtherInterAttr =
    CreateOrSetAttributeValueFromOtherInterAttr


setAttributeValue : AttrTypes -> String -> String -> ChangeWorldCommand
setAttributeValue val attrId interactableId =
    let
        reservedAttrIds =
            Engine.Manifest.getReservedAttrIds
    in
        if (not (List.member attrId reservedAttrIds)) then
            CreateAttributeIfNotExistsAndOrSetValue val attrId interactableId
        else
            let
                _ =
                    Debug.log "Sorry ! It was not possible to set attribute value . That's a 'reserved' attributeId : " attrId
            in
                NoChange


removeAttributeIfExists : String -> String -> ChangeWorldCommand
removeAttributeIfExists =
    RemoveAttributeIfExists


{-| Adds a character to a location, or moves a character to a different location (characters can only be in one location at a time, or off-screen). (Use moveTo to move yourself between locations.)

The first String is a character id, the second is a location id.

-}
moveCharacterToLocation : String -> String -> ChangeWorldCommand
moveCharacterToLocation =
    MoveCharacterToLocation


{-| Moves a character "off-screen". The character will not show up in any locations until you use `moveCharacterToLocation` again.
-}
moveCharacterOffScreen : String -> ChangeWorldCommand
moveCharacterOffScreen =
    MoveCharacterOffScreen


{-| Move an item to a location and set it as "fixed." Fixed items are like scenery, they can be interacted with, but they cannot be added to inventory.

If it was in another location or your inventory before, it will remove it from there, as items can only be in one place at once.

The first String is an item id, the second is a location id.

-}
moveItemToLocationFixed : String -> String -> ChangeWorldCommand
moveItemToLocationFixed =
    MoveItemToLocationFixed


{-| Move an item to a location. If it was in another location or your inventory before, it will remove it from there, as items can only be in one place at once.

The first String is an item id, the second is a location id.

-}
moveItemToLocation : String -> String -> ChangeWorldCommand
moveItemToLocation =
    MoveItemToLocation


{-| Moves an item "off-screen" (either from a location or the inventory). The item will not show up in any locations or inventory until you use `placeItem` or `addInventory` again.
-}
moveItemOffScreen : String -> ChangeWorldCommand
moveItemOffScreen =
    MoveItemOffScreen


{-| adds a language to the list of languages the user can choose from
first arg : LanguageId , second arg : Language , example : "gr" "greek"
-}
addChoiceLanguage : String -> String -> ChangeWorldCommand
addChoiceLanguage =
    AddChoiceLanguage


checkAnswerData : Maybe Int -> AnswerCase -> AnswerSpaces -> AnswerFeedback -> Dict String String -> Dict String String -> List ( String, AttrTypes ) -> List ( String, String, AttrTypes ) -> CheckAnswerData
checkAnswerData =
    CheckAnswerData


checkBkendAnswerData : Maybe Int -> AnswerFeedback -> List ( String, AttrTypes ) -> List ( String, String, AttrTypes ) -> CheckBkendAnswerData
checkBkendAnswerData =
    CheckBkendAnswerData


checkOptionData : String -> Dict String String -> List ( String, AttrTypes ) -> List ( String, String, AttrTypes ) -> CheckOptionData
checkOptionData =
    CheckOptionData


astring : String -> AttrTypes
astring =
    Astring


aliststring : List String -> AttrTypes
aliststring =
    AListString


aliststringstring : List ( String, String ) -> AttrTypes
aliststringstring =
    AListStringString


anint : Int -> AttrTypes
anint =
    AnInt


abool : Bool -> AttrTypes
abool =
    Abool


aDictStringString : Dict String String -> AttrTypes
aDictStringString =
    ADictStringString


aDictStringLSS : Dict String (List ( String, String )) -> AttrTypes
aDictStringLSS =
    ADictStringLSS


completeTheRule : Rule_ -> Rule
completeTheRule ruleData =
    --returns a rule with  the 'null' quasiChangeWorldCommands
    Rule ruleData.interaction ruleData.conditions ruleData.changes [] NoQuasiChangeWithBackend


caseSensitiveAnswer : Types.AnswerCase
caseSensitiveAnswer =
    CaseSensitiveAnswer


caseInsensitiveAnswer : Types.AnswerCase
caseInsensitiveAnswer =
    CaseInsensitiveAnswer


answerSpacesMatter : Types.AnswerSpaces
answerSpacesMatter =
    AnswerSpacesMatter


answerSpacesDontMatter : Types.AnswerSpaces
answerSpacesDontMatter =
    AnswerSpacesDontMatter


headerAnswerAndCorrectIncorrect : Types.AnswerFeedback
headerAnswerAndCorrectIncorrect =
    HeaderAnswerAndCorrectIncorrect


noFeedback : Types.AnswerFeedback
noFeedback =
    NoFeedback


noQuasiChange : Types.QuasiChangeWorldCommand
noQuasiChange =
    NoQuasiChange


noQuasiChangeWithBackend : Types.QuasiChangeWorldCommandWithBackendInfo
noQuasiChangeWithBackend =
    NoQuasiChangeWithBackend


{-| Scenes are a way to further constrain rules. You could have a scene for each leg of your story to make sure only the rules for that scene will apply. Or you may start a scene at a turning point in your story to "activate" special rules that apply to that scene. This is how you start or switch to a new scene. Note that you can only have one scene active at at time.
-}
loadScene : String -> ChangeWorldCommand
loadScene =
    LoadScene


{-| Sets a flag that the story has ended. The string you provide can be used to signify the "type" of story ending ("good", "bad", "heroic", etc), or how many moves it took to complete, or anything else you like. This has no effect on the framework, but you can use it in your client code how ever you like (change the view, calculate a score, etc).
-}
endStory : String -> String -> ChangeWorldCommand
endStory endingtypeStr ending =
    if (endingtypeStr == "notFreezingEnd") then
        EndStory NotFreezingEnd ending
    else
        EndStory FreezingEnd ending


endStory_ : EndingType -> String -> ChangeWorldCommand
endStory_ endingtype ending =
    EndStory endingtype ending
