module Engine.Manifest
    exposing
        ( init
        , character
        , characterIsInLocation
        , getCharactersInLocation
        , getItemsInLocation
        , getItemsInLocationIncludeWrittenContent
        , getItemsInInventory
        , getItemsInInventoryIncludeWrittenContent
        , getItemWrittenContent
        , getInteractableAttribute
        , countWritableItemsInLocation
        , getLocations
        , isCharacter
        , isItem
        , isLocation
        , item
        , itemIsInInventory
        , itemIsInLocation
        , itemIsNotInLocation
        , itemIsOffScreen
        , itemIsInAnyLocationOrInventory
        , itemIsCorrectlyAnswered
        , itemIsNotCorrectlyAnswered
        , itemIsIncorrectlyAnswered
        , itemIsNotAnswered
        , isWritable
        , location
        , counterExists
        , counterLessThen
        , counterGreaterThenOrEqualTo
        , attrValueIsEqualTo
        , chosenOptionIsEqualTo
        , noChosenOptionYet
        , choiceHasAlreadyBeenMade
        , getReservedAttrIds
        , update
        )

import Types exposing (..)
import Dict exposing (Dict)
import Regex


init :
    { items : List String
    , locations : List String
    , characters : List String
    }
    -> Manifest
init { items, locations, characters } =
    let
        insertFn interactableConstructor id acc =
            Dict.insert id (interactableConstructor id) acc

        foldFn interactableConstructor interactableList acc =
            List.foldr (insertFn interactableConstructor) acc interactableList
    in
        Dict.empty
            |> foldFn item items
            |> foldFn location locations
            |> foldFn character characters


item : String -> Interactable
item itemId =
    let
        --ItemData  interactableId fixed  itemPlacement  isWritable  writtenContent  attributes  interactionErrors interactionWarnings
        itemData =
            ItemData itemId False ItemOffScreen False Nothing Dict.empty [] []
    in
        Item itemData


location : String -> Interactable
location locationId =
    let
        --  LocationData interactableId  shown    attributes  interactionErrors interactionWarnings
        locationData =
            LocationData locationId False Dict.empty [] []
    in
        Location locationData


character : String -> Interactable
character caharacterId =
    let
        --  CharacterData  interactableId  characterPlacement  attributes   interactionErrors  interactionWarnings
        characterData =
            CharacterData caharacterId CharacterOffScreen Dict.empty [] []
    in
        Character characterData


getItemsInInventory : Manifest -> List String
getItemsInInventory manifest =
    let
        isInInventory ( id, interactable ) =
            case interactable of
                Item idata ->
                    if (idata.itemPlacement == ItemInInventory) then
                        Just id
                    else
                        Nothing

                _ ->
                    Nothing
    in
        Dict.toList manifest
            |> List.filterMap isInInventory


getItemsInInventoryIncludeWrittenContent : Manifest -> List ( String, Maybe String )
getItemsInInventoryIncludeWrittenContent manifest =
    let
        isInInventory ( id, interactable ) =
            case interactable of
                Item idata ->
                    if (idata.itemPlacement == ItemInInventory) then
                        Just ( id, idata.writtenContent )
                    else
                        Nothing

                _ ->
                    Nothing
    in
        Dict.toList manifest
            |> List.filterMap isInInventory


getLocations : Manifest -> List String
getLocations manifest =
    let
        isShownLocation ( id, interactable ) =
            case interactable of
                Location locData ->
                    if locData.shown then
                        Just id
                    else
                        Nothing

                _ ->
                    Nothing
    in
        Dict.toList manifest
            |> List.filterMap isShownLocation


getCharactersInLocation : String -> Manifest -> List String
getCharactersInLocation locationId manifest =
    let
        isInLocation locId ( id, interactable ) =
            case interactable of
                Character cdata ->
                    case cdata.characterPlacement of
                        CharacterInLocation location ->
                            if location == locId then
                                Just id
                            else
                                Nothing

                        _ ->
                            Nothing

                _ ->
                    Nothing
    in
        Dict.toList manifest
            |> List.filterMap (isInLocation locationId)


getItemsInLocation : String -> Manifest -> List String
getItemsInLocation locationId manifest =
    let
        isInLocation locationId ( id, interactable ) =
            case interactable of
                Item idata ->
                    case idata.itemPlacement of
                        ItemInLocation locId ->
                            if (locId == locationId) then
                                Just id
                            else
                                Nothing

                        _ ->
                            Nothing

                _ ->
                    Nothing
    in
        Dict.toList manifest
            |> List.filterMap (isInLocation locationId)


countWritableItemsInLocation : String -> Manifest -> Int
countWritableItemsInLocation locationId manifest =
    let
        isInLocationAndWritable locationId ( id, interactable ) =
            case interactable of
                Item idata ->
                    case idata.itemPlacement of
                        ItemInLocation locId ->
                            if (locId == locationId && idata.isWritable) then
                                Just id
                            else
                                Nothing

                        _ ->
                            Nothing

                _ ->
                    Nothing
    in
        Dict.toList manifest
            |> List.filterMap (isInLocationAndWritable locationId)
            |> List.length


isWritable : String -> Manifest -> Bool
isWritable interactableId manifest =
    Dict.get interactableId manifest
        |> \mbinteractable ->
            case mbinteractable of
                Just (Item idata) ->
                    idata.isWritable

                _ ->
                    False


getItemsInLocationIncludeWrittenContent : String -> Manifest -> List ( String, Maybe String )
getItemsInLocationIncludeWrittenContent locationId manifest =
    let
        isInLocation locationId ( id, interactable ) =
            case interactable of
                Item idata ->
                    case idata.itemPlacement of
                        ItemInLocation locId ->
                            if (locId == locationId) then
                                Just ( id, idata.writtenContent )
                            else
                                Nothing

                        _ ->
                            Nothing

                _ ->
                    Nothing
    in
        Dict.toList manifest
            |> List.filterMap (isInLocation locationId)


isItem : String -> Manifest -> Bool
isItem id manifest =
    Dict.get id manifest
        |> \interactable ->
            case interactable of
                Just (Item idata) ->
                    True

                _ ->
                    False


isLocation : String -> Manifest -> Bool
isLocation id manifest =
    Dict.get id manifest
        |> \interactable ->
            case interactable of
                Just (Location _) ->
                    True

                _ ->
                    False


isCharacter : String -> Manifest -> Bool
isCharacter id manifest =
    Dict.get id manifest
        |> \interactable ->
            case interactable of
                Just (Character cdata) ->
                    True

                _ ->
                    False


noChosenOptionYet : String -> Manifest -> Bool
noChosenOptionYet interactableId manifest =
    Dict.get interactableId manifest
        |> \interactable ->
            case interactable of
                Just (Item idata) ->
                    if
                        (Dict.get "answerOptionsList" idata.attributes
                            /= Nothing
                            && Dict.get "chosenOption" idata.attributes
                            == Nothing
                        )
                    then
                        True
                    else
                        False

                _ ->
                    False


choiceHasAlreadyBeenMade : String -> Manifest -> Bool
choiceHasAlreadyBeenMade interactableId manifest =
    not <| noChosenOptionYet interactableId manifest


chosenOptionIsEqualTo : String -> Maybe String -> Bool
chosenOptionIsEqualTo valueToMatch mbInputText =
    if (Just valueToMatch == mbInputText) then
        True
    else
        False


checkForNonExistantInteractableId : String -> Manifest -> List String -> List String
checkForNonExistantInteractableId interactableId manifest linteractionincidents =
    case (Dict.get interactableId manifest) of
        Nothing ->
            List.append linteractionincidents [ "Interactable with InteractableId : " ++ interactableId ++ " doesn't exist !" ]

        Just interactable ->
            linteractionincidents


checkForNonExistantLocationId : String -> Manifest -> List String -> List String
checkForNonExistantLocationId locationId manifest linteractionincidents =
    case (Dict.get locationId manifest) of
        Nothing ->
            List.append linteractionincidents [ "Problem on interaction with Location . LocationId : " ++ locationId ++ " doesn't exist !" ]

        Just interactable ->
            linteractionincidents


manifestUpdate : String -> (Maybe Interactable -> Maybe Interactable) -> ( Manifest, List String ) -> ( Manifest, List String )
manifestUpdate interactbaleId updateFuncMbToMb ( manifest, linteractionincidents ) =
    let
        newManifest =
            Dict.update interactbaleId updateFuncMbToMb manifest

        newInteractionIncidents =
            linteractionincidents
                |> checkForNonExistantInteractableId interactbaleId manifest

        -- add the interactionErrors and the interactionWarnings info from the interactable
        incidentswithInterErrors =
            getInteractionErrors interactbaleId manifest
                |> List.map (\x -> ("Interaction Error : " ++ x))
                |> List.append newInteractionIncidents

        incidentswithInterErrorsAndWarnings =
            getInteractionWarnings interactbaleId manifest
                |> List.map (\x -> ("Interaction Warning : " ++ x))
                |> List.append incidentswithInterErrors

        -- clear the interactionErrors and interactionWarnings on the interactable
        newManifestUpdated =
            newManifest
                |> Dict.update interactbaleId (clearInteractionIncidents "warning")
                |> Dict.update interactbaleId (clearInteractionIncidents "error")
    in
        ( newManifestUpdated, incidentswithInterErrorsAndWarnings )


manifestUpdateWithLocCheck : String -> String -> (Maybe Interactable -> Maybe Interactable) -> ( Manifest, List String ) -> ( Manifest, List String )
manifestUpdateWithLocCheck interactbaleId locationId updateFuncMbToMb ( manifest, linteractionincidents ) =
    let
        newManifest =
            Dict.update interactbaleId updateFuncMbToMb manifest

        newInteractionIncidents =
            linteractionincidents
                |> checkForNonExistantInteractableId interactbaleId manifest
                |> checkForNonExistantLocationId locationId manifest

        -- add the interactionErrors and the interactionWarnings info from the interactable
        incidentswithInterErrors =
            getInteractionErrors interactbaleId manifest
                |> List.map (\x -> ("Interaction Error : " ++ x))
                |> List.append newInteractionIncidents

        incidentswithInterErrorsAndWarnings =
            getInteractionWarnings interactbaleId manifest
                |> List.map (\x -> ("Interaction Warning : " ++ x))
                |> List.append incidentswithInterErrors

        -- clear the interactionErrors and interactionWarnings on the interactable
        newManifestUpdated =
            newManifest
                |> Dict.update interactbaleId (clearInteractionIncidents "warning")
                |> Dict.update interactbaleId (clearInteractionIncidents "error")
    in
        ( newManifestUpdated, incidentswithInterErrorsAndWarnings )


update : ChangeWorldCommand -> ( Manifest, List String ) -> ( Manifest, List String )
update change ( manifest, linteractionincidents ) =
    case change of
        NoChange ->
            ( manifest, linteractionincidents )

        MoveTo id ->
            manifestUpdate id addLocation ( manifest, linteractionincidents )

        AddLocation id ->
            manifestUpdate id addLocation ( manifest, linteractionincidents )

        RemoveLocation id ->
            manifestUpdate id removeLocation ( manifest, linteractionincidents )

        MoveItemToInventory id ->
            manifestUpdate id moveItemToInventory ( manifest, linteractionincidents )

        MoveItemToLocation itemId locationId ->
            manifestUpdate itemId (moveItemToLocation locationId) ( manifest, linteractionincidents )

        MoveItemToLocationFixed itemId locationId ->
            manifestUpdateWithLocCheck itemId locationId (moveItemToLocationFixed locationId) ( manifest, linteractionincidents )

        MoveItemOffScreen id ->
            manifestUpdate id moveItemOffScreen ( manifest, linteractionincidents )

        MoveCharacterToLocation characterId locationId ->
            manifestUpdateWithLocCheck characterId locationId (moveCharacterToLocation locationId) ( manifest, linteractionincidents )

        MoveCharacterOffScreen id ->
            manifestUpdate id moveCharacterOffScreen ( manifest, linteractionincidents )

        WriteTextToItem theText id ->
            manifestUpdate id (writeTextToItem theText) ( manifest, linteractionincidents )

        WriteForceTextToItemFromGivenItemAttr attrid intcId id ->
            manifestUpdate id (writeForceTextToItemFromOtherInteractableAttrib attrid intcId manifest) ( manifest, linteractionincidents )

        WriteGpsLocInfoToItem theInfoStr id ->
            manifestUpdate id (writeGpsLocInfoToItem theInfoStr) ( manifest, linteractionincidents )

        ClearWrittenText id ->
            manifestUpdate id (clearWrittenText) ( manifest, linteractionincidents )

        CheckIfAnswerCorrect theText playerAnswer cAnswerData interactableId ->
            manifestUpdate interactableId (checkIfAnswerCorrect theText playerAnswer cAnswerData) ( manifest, linteractionincidents )
                |> processCreateOrSetOtherInteractableAttributesIfAnswerCorrect cAnswerData.lotherInterAttrs interactableId

        CheckAndActIfChosenOptionIs playerChoice cOptionData interactableId ->
            manifestUpdate interactableId (checkAndActIfChosenOptionIs playerChoice cOptionData) ( manifest, linteractionincidents )
                |> processCreateOrSetOtherInteractableAttributesIfChosenOptionIs playerChoice cOptionData.valueToMatch cOptionData.lotherInterAttrs interactableId

        ProcessChosenOptionEqualTo cOptionData id ->
            manifestUpdate id (processChosenOptionEqualTo cOptionData) ( manifest, linteractionincidents )

        CreateAMultiChoice dslss id ->
            manifestUpdate id (createAmultiChoice dslss) ( manifest, linteractionincidents )

        RemoveMultiChoiceOptions id ->
            manifestUpdate id (removeMultiChoiceOptions) ( manifest, linteractionincidents )

        CreateCounterIfNotExists counterId interactableId ->
            manifestUpdate interactableId (createCounterIfNotExists counterId) ( manifest, linteractionincidents )

        IncreaseCounter counterId interactableId ->
            manifestUpdate interactableId (increaseCounter counterId) ( manifest, linteractionincidents )

        CreateAttributeIfNotExists attrValue attrId interactableId ->
            manifestUpdate interactableId (createAttributeIfNotExists attrValue attrId) ( manifest, linteractionincidents )

        SetAttributeValue attrValue attrId interactableId ->
            manifestUpdate interactableId (setAttributeValue attrValue attrId) ( manifest, linteractionincidents )

        CreateAttributeIfNotExistsAndOrSetValue attrValue attrId interactableId ->
            manifestUpdate interactableId (createAttributeIfNotExistsAndOrSetValue attrValue attrId) ( manifest, linteractionincidents )

        CreateOrSetAttributeValueFromOtherInterAttr attrId otherInterAtrrId otherInterId interactableId ->
            manifestUpdate interactableId (createOrSetAttributeValueFromOtherInterAttr attrId otherInterAtrrId otherInterId manifest) ( manifest, linteractionincidents )

        RemoveAttributeIfExists attrId interactableId ->
            manifestUpdate interactableId (removeAttributeIfExists attrId) ( manifest, linteractionincidents )

        MakeItemWritable id ->
            manifestUpdate id makeItemWritable ( manifest, linteractionincidents )

        MakeItemUnwritable id ->
            manifestUpdate id makeItemUnwritable ( manifest, linteractionincidents )

        RemoveChooseOptions id ->
            manifestUpdate id removeChooseOptions ( manifest, linteractionincidents )

        MakeItUnanswerable id ->
            manifestUpdate id makeItUnanswerable ( manifest, linteractionincidents )

        LoadScene str ->
            -- doesnt imply a change in the manifest. It is handled in Engine.changeWorld only
            ( manifest, linteractionincidents )

        SetChoiceLanguages d ->
            -- doesnt imply a change in the manifest. It is handled in Engine.changeWorld only
            ( manifest, linteractionincidents )

        AddChoiceLanguage s1 s2 ->
            -- doesnt imply a change in the manifest. It is handled in Engine.changeWorld only
            ( manifest, linteractionincidents )

        EndStory t s ->
            -- doesnt imply a change in the manifest. It is handled in Engine.changeWorld only
            ( manifest, linteractionincidents )


createAmultiChoice : Dict String (List ( String, String )) -> Maybe Interactable -> Maybe Interactable
createAmultiChoice dslss mbInteractable =
    createAttributeIfNotExistsAndOrSetValue (ADictStringLSS dslss) "answerOptionsList" mbInteractable
        |> removeAttributeIfExists "chosenOption"


removeMultiChoiceOptions : Maybe Interactable -> Maybe Interactable
removeMultiChoiceOptions mbInteractable =
    removeAttributeIfExists "answerOptionsList" mbInteractable


processCreateOrSetOtherInteractableAttributesIfAnswerCorrect : List ( String, String, AttrTypes ) -> String -> ( Manifest, List String ) -> ( Manifest, List String )
processCreateOrSetOtherInteractableAttributesIfAnswerCorrect lotherInterAttrs interactableId ( manifest, linteractionincidents ) =
    if (attrValueIsEqualTo (Abool True) "isCorrectlyAnswered" interactableId manifest) then
        List.map (\( interactableId, attrId, attrValue ) -> CreateAttributeIfNotExistsAndOrSetValue attrValue attrId interactableId) lotherInterAttrs
            |> List.foldl (\chg tup -> update chg tup) ( manifest, linteractionincidents )
    else
        ( manifest, linteractionincidents )


processCreateOrSetOtherInteractableAttributesIfChosenOptionIs : String -> String -> List ( String, String, AttrTypes ) -> String -> ( Manifest, List String ) -> ( Manifest, List String )
processCreateOrSetOtherInteractableAttributesIfChosenOptionIs playerChoice valToMatch lotherInterAttrs interactableId ( manifest, linteractionincidents ) =
    if (playerChoice == valToMatch) then
        List.map (\( interactableId, attrId, attrValue ) -> CreateAttributeIfNotExistsAndOrSetValue attrValue attrId interactableId) lotherInterAttrs
            |> List.foldl (\chg tup -> update chg tup) ( manifest, linteractionincidents )
    else
        ( manifest, linteractionincidents )


getInteractionErrors : String -> Manifest -> List String
getInteractionErrors interactableId manifest =
    case (Dict.get interactableId manifest) of
        Just (Item idata) ->
            idata.interactionErrors

        Just (Character cdata) ->
            cdata.interactionErrors

        Just (Location ldata) ->
            ldata.interactionErrors

        Nothing ->
            []


getInteractionWarnings : String -> Manifest -> List String
getInteractionWarnings interactableId manifest =
    case (Dict.get interactableId manifest) of
        Just (Item idata) ->
            idata.interactionWarnings

        Just (Character cdata) ->
            cdata.interactionWarnings

        Just (Location ldata) ->
            ldata.interactionWarnings

        Nothing ->
            []


createCounterIfNotExists : String -> Maybe Interactable -> Maybe Interactable
createCounterIfNotExists counterId mbinteractable =
    let
        getNewDataRecord : String -> { a | attributes : Dict String AttrTypes } -> { a | attributes : Dict String AttrTypes }
        getNewDataRecord thecounterId dataRecord =
            let
                counterStrID =
                    "counter_" ++ thecounterId

                newAttributes =
                    case (Dict.get counterStrID dataRecord.attributes) of
                        Nothing ->
                            Dict.insert counterStrID (AnInt 0) dataRecord.attributes

                        Just c ->
                            dataRecord.attributes

                newDataRecord =
                    { dataRecord | attributes = newAttributes }
            in
                newDataRecord
    in
        case mbinteractable of
            Just (Item idata) ->
                Just (Item <| getNewDataRecord counterId idata)

            Just (Character cdata) ->
                Just (Character <| getNewDataRecord counterId cdata)

            Just (Location ldata) ->
                Just (Location <| getNewDataRecord counterId ldata)

            Nothing ->
                Nothing


increaseCounter : String -> Maybe Interactable -> Maybe Interactable
increaseCounter counterId mbinteractable =
    let
        getNewDataRecord : String -> { a | attributes : Dict String AttrTypes } -> { a | attributes : Dict String AttrTypes }
        getNewDataRecord thecounterId dataRecord =
            let
                counterStrID =
                    "counter_" ++ thecounterId

                newAttributes =
                    case (Dict.get counterStrID dataRecord.attributes) of
                        Nothing ->
                            dataRecord.attributes

                        Just attrval ->
                            case attrval of
                                AnInt val ->
                                    Dict.update counterStrID (\_ -> Just (AnInt (val + 1))) dataRecord.attributes

                                _ ->
                                    dataRecord.attributes

                newDataRecord =
                    { dataRecord | attributes = newAttributes }
            in
                newDataRecord
    in
        case mbinteractable of
            Just (Item idata) ->
                Just (Item <| getNewDataRecord counterId idata)

            Just (Character cdata) ->
                Just (Character <| getNewDataRecord counterId cdata)

            Just (Location ldata) ->
                Just (Location <| getNewDataRecord counterId ldata)

            Nothing ->
                Nothing


createAttributeIfNotExists : AttrTypes -> String -> Maybe Interactable -> Maybe Interactable
createAttributeIfNotExists initialVal attrId mbinteractable =
    let
        getNewDataRecord : AttrTypes -> String -> { a | attributes : Dict String AttrTypes } -> { a | attributes : Dict String AttrTypes }
        getNewDataRecord theInitialVal theAttrId dataRecord =
            let
                newAttributes =
                    case (Dict.get theAttrId dataRecord.attributes) of
                        Nothing ->
                            Dict.insert theAttrId theInitialVal dataRecord.attributes

                        Just c ->
                            dataRecord.attributes

                newDataRecord =
                    { dataRecord | attributes = newAttributes }
            in
                newDataRecord
    in
        case mbinteractable of
            Just (Item idata) ->
                Just (Item <| getNewDataRecord initialVal attrId idata)

            Just (Character cdata) ->
                Just (Character <| getNewDataRecord initialVal attrId cdata)

            Just (Location ldata) ->
                Just (Location <| getNewDataRecord initialVal attrId ldata)

            Nothing ->
                Nothing


writeInteractionIncident : String -> String -> Maybe Interactable -> Maybe Interactable
writeInteractionIncident incidentType incidentStr mbInteractable =
    let
        writeHelper : String -> String -> { a | interactableId : String, interactionErrors : List String, interactionWarnings : List String } -> { a | interactableId : String, interactionErrors : List String, interactionWarnings : List String }
        writeHelper theIncidentType theIncidentStr dataRecord =
            let
                descriptionStr : String
                descriptionStr =
                    theIncidentStr ++ "InteractableId : " ++ dataRecord.interactableId
            in
                if (theIncidentType == "warning") then
                    { dataRecord | interactionWarnings = descriptionStr :: dataRecord.interactionWarnings }
                else
                    { dataRecord | interactionErrors = descriptionStr :: dataRecord.interactionErrors }
    in
        case mbInteractable of
            Just (Item idata) ->
                Just (Item <| writeHelper incidentType incidentStr idata)

            Just (Character cdata) ->
                Just (Character <| writeHelper incidentType incidentStr cdata)

            Just (Location ldata) ->
                Just (Location <| writeHelper incidentType incidentStr ldata)

            Nothing ->
                Nothing


clearInteractionIncidents : String -> Maybe Interactable -> Maybe Interactable
clearInteractionIncidents incidentType mbInteractable =
    let
        clearHelper : String -> { a | interactableId : String, interactionErrors : List String, interactionWarnings : List String } -> { a | interactableId : String, interactionErrors : List String, interactionWarnings : List String }
        clearHelper theIncidentType dataRecord =
            if (theIncidentType == "warning") then
                { dataRecord | interactionWarnings = [] }
            else
                { dataRecord | interactionErrors = [] }
    in
        case mbInteractable of
            Just (Item idata) ->
                Just (Item <| clearHelper incidentType idata)

            Just (Character cdata) ->
                Just (Character <| clearHelper incidentType cdata)

            Just (Location ldata) ->
                Just (Location <| clearHelper incidentType ldata)

            Nothing ->
                Nothing


addLocation : Maybe Interactable -> Maybe Interactable
addLocation mbInteractable =
    case mbInteractable of
        Just (Location ldata) ->
            let
                newldata =
                    { ldata | shown = True }
            in
                Just (Location newldata)

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use addLocation function with an interactable that is not a Location ! "


removeLocation : Maybe Interactable -> Maybe Interactable
removeLocation mbInteractable =
    case mbInteractable of
        Just (Location ldata) ->
            let
                newldata =
                    { ldata | shown = False }
            in
                Just (Location newldata)

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use removeLocation function with an interactable that is not a Location ! "


moveItemToInventory : Maybe Interactable -> Maybe Interactable
moveItemToInventory mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            if (not idata.fixed) then
                Just (Item { idata | itemPlacement = ItemInInventory })
            else
                mbInteractable
                    |> writeInteractionIncident "warning" "Trying to use moveItemToInventory function with an interactable that is an Item fixed to a Location . Can't be moved ! "

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveItemToInventory function with an interactable that is not an Item ! "


moveItemOffScreen : Maybe Interactable -> Maybe Interactable
moveItemOffScreen mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | fixed = False, itemPlacement = ItemOffScreen })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveItemOffScreen function with an interactable that is not an Item ! "


moveItemToLocationFixed : String -> Maybe Interactable -> Maybe Interactable
moveItemToLocationFixed locationId mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | fixed = True, itemPlacement = ItemInLocation locationId })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveItemToLocationFixed function with an interactable that is not an Item ! "


moveItemToLocation : String -> Maybe Interactable -> Maybe Interactable
moveItemToLocation locationId mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            -- still have to Check if location exists
            Just (Item { idata | fixed = False, itemPlacement = ItemInLocation locationId })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveItemToLocation function with an interactable that is not an Item ! "


makeItemWritable : Maybe Interactable -> Maybe Interactable
makeItemWritable mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | isWritable = True })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use makeItemWritable function with an interactable that is not an Item ! "


makeItemUnwritable : Maybe Interactable -> Maybe Interactable
makeItemUnwritable mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | isWritable = False })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use makeItemUnwritable function with an interactable that is not an Item ! "


{-| if the interactable has some options/answers associated with it from which the user can chose
this function will remove those options ( buttons ) by removing the attribute
responsible for their display on the storyline
-}
removeChooseOptions : Maybe Interactable -> Maybe Interactable
removeChooseOptions mbinteractable =
    removeAttributeIfExists "answerOptionsList" mbinteractable


{-| makes simultaneously the item unwritable ( answerBox is removed if there was one )
and also removes choice options/buttons if they were available that might allow a player to answer something
-}
makeItUnanswerable : Maybe Interactable -> Maybe Interactable
makeItUnanswerable mbinteractable =
    makeItemUnwritable mbinteractable
        |> removeChooseOptions


{-| writes text to the writtenContent of the Item if the item isWritable
-}
writeTextToItem : String -> Maybe Interactable -> Maybe Interactable
writeTextToItem theText mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            if idata.isWritable then
                Just (Item { idata | writtenContent = Just theText })
            else
                mbinteractable
                    |> writeInteractionIncident "warning" "Trying to use writeTextToItem function with an interactable that is a notWritable Item ! "

        Nothing ->
            Nothing

        _ ->
            mbinteractable
                |> writeInteractionIncident "error" "Trying to use writeTextToItem function with an interactable that is not an Item ! "


writeForceTextToItemFromOtherInteractableAttrib : String -> String -> Manifest -> Maybe Interactable -> Maybe Interactable
writeForceTextToItemFromOtherInteractableAttrib attrid intcId manifest mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            let
                theAttrVal =
                    -- still have to check if other InteractableId exists
                    getInteractableAttribute attrid (Dict.get intcId manifest)

                theText =
                    case theAttrVal of
                        Just (Abool bval) ->
                            toString bval

                        Just (Astring s) ->
                            s

                        Just (AnInt i) ->
                            toString i

                        _ ->
                            ""
            in
                Just (Item { idata | writtenContent = Just theText })

        Nothing ->
            Nothing

        _ ->
            mbinteractable
                |> writeInteractionIncident "error" "Trying to use writeForceTextToItemFromOtherInteractableAttrib function with an interactable that is not an Item ! "


{-| writes info to the item regardless of whether the item is writable or not.
we don't want to make the item writable because an input textbox would be displayed to the user
, but we still want to write this info to the item , so ...
-}
writeGpsLocInfoToItem : String -> Maybe Interactable -> Maybe Interactable
writeGpsLocInfoToItem infoText mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | writtenContent = Just infoText })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use writeGpsLocInfoToItem function with an interactable that is not an Item ! "


clearWrittenText : Maybe Interactable -> Maybe Interactable
clearWrittenText mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            Just (Item { idata | writtenContent = Nothing })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use clearWrittenText function with an interactable that is not an Item ! "


getItemWrittenContent : Maybe Interactable -> Maybe String
getItemWrittenContent mbInteractable =
    case mbInteractable of
        Just (Item idata) ->
            idata.writtenContent

        _ ->
            Nothing


checkIfAnswerCorrect : List String -> String -> CheckAnswerData -> Maybe Interactable -> Maybe Interactable
checkIfAnswerCorrect theCorrectAnswers playerAnswer checkAnsData mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            let
                correct =
                    "  \n ___CORRECT_ANSWER___"

                incorrect =
                    "  \n ___INCORRECT_ANSWER___"

                reach_max_nr_tries =
                    "___REACH_MAX_NR_TRIES___"

                playerAns =
                    if (checkAnsData.answerFeedback == JustPlayerAnswer || checkAnsData.answerFeedback == HeaderAndAnswer || checkAnsData.answerFeedback == HeaderAnswerAndCorrectIncorrect) then
                        "  \n ___YOUR_ANSWER___" ++ " " ++ playerAnswer
                    else
                        ""

                answerFeedback =
                    correct
                        ++ "  \n"
                        |> (\x ->
                                if (checkAnsData.answerFeedback == HeaderAnswerAndCorrectIncorrect) then
                                    x
                                else
                                    ""
                           )

                ansRight =
                    playerAns ++ answerFeedback

                maxNrTries =
                    Maybe.withDefault -999 checkAnsData.mbMaxNrTries

                getAnsWrong nrTries theMax =
                    let
                        ansFeedback =
                            if (theMax > 0 && nrTries >= (theMax - 1)) then
                                "  \n" ++ " " ++ reach_max_nr_tries
                            else
                                incorrect
                                    ++ if theMax > 0 then
                                        "  \n" ++ " " ++ "___NR_TRIES_LEFT___" ++ " " ++ toString (theMax - 1 - nrTries)
                                       else
                                        ""
                    in
                        playerAns
                            ++ if (checkAnsData.answerFeedback == HeaderAnswerAndCorrectIncorrect) then
                                ansFeedback
                               else
                                ""

                nrTries =
                    getICounterValue "nrIncorrectAnswers" mbinteractable
                        |> Maybe.withDefault 0

                makeItUnanswarableIfReachedMaxTries : Int -> Maybe Interactable -> Maybe Interactable
                makeItUnanswarableIfReachedMaxTries maxnr mbinter =
                    let
                        nrtries =
                            Maybe.withDefault 0 (getICounterValue "nrIncorrectAnswers" mbinteractable)
                    in
                        if (maxnr > 0 && nrtries >= maxnr) then
                            --makeItemUnwritable mbinter
                            makeItUnanswerable mbinter
                        else
                            mbinter

                theMbInteractable =
                    if (maxNrTries > 0 && nrTries >= maxNrTries) then
                        mbinteractable
                            |> makeItUnanswerable
                    else if
                        (playerAnswer
                            == ""
                            || Dict.get "isCorrectlyAnswered" idata.attributes
                            == Just (Abool True)
                        )
                    then
                        mbinteractable
                        -- if no answer was provided or correct answer was previously provided returns the exact same maybe interactable
                    else if (comparesEqualToAtLeastOne playerAnswer theCorrectAnswers checkAnsData.answerCase checkAnsData.answerSpaces) then
                        Just (Item { idata | writtenContent = (Just ansRight) })
                            |> makeItUnanswerable
                            |> createAttributeIfNotExistsAndOrSetValue (Astring playerAnswer) "playerAnswer"
                            |> createAttributeIfNotExistsAndOrSetValue (Abool True) "isCorrectlyAnswered"
                            |> removeAttributeIfExists "isIncorrectlyAnswered"
                            |> createAttributeIfNotExistsAndOrSetValue (Astring "___QUESTION_ANSWERED___") "narrativeHeader"
                            |> createAttributeIfNotExistsAndOrSetValue (ADictStringString checkAnsData.correctAnsTextDict) "additionalTextDict"
                            |> createAttributesIfNotExistsAndOrSetValue checkAnsData.lnewAttrs
                    else
                        Just (Item { idata | writtenContent = (Just (getAnsWrong nrTries maxNrTries)) })
                            |> createAttributeIfNotExistsAndOrSetValue (Astring playerAnswer) "playerAnswer"
                            |> createAttributeIfNotExistsAndOrSetValue (Abool True) "isIncorrectlyAnswered"
                            |> removeAttributeIfExists "isCorrectlyAnswered"
                            |> createAttributeIfNotExistsAndOrSetValue (ADictStringString checkAnsData.incorrectAnsTextDict) "additionalTextDict"
                            |> createCounterIfNotExists "nrIncorrectAnswers"
                            |> makeItUnanswarableIfReachedMaxTries (maxNrTries - 1)
                            |> increaseCounter "nrIncorrectAnswers"
            in
                theMbInteractable

        Nothing ->
            Nothing

        _ ->
            mbinteractable
                |> writeInteractionIncident "error" "Trying to use checkIfAnswerCorrect function with an interactable that is not an Item ! "


checkAndActIfChosenOptionIs : String -> CheckOptionData -> Maybe Interactable -> Maybe Interactable
checkAndActIfChosenOptionIs playerChoice cOptionData mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            let
                choiceStr =
                    "  \n ___YOUR_CHOICE___" ++ " " ++ playerChoice

                theMbInteractable =
                    if
                        (playerChoice
                            == ""
                            || Dict.get "chosenOption" idata.attributes
                            /= Nothing
                        )
                    then
                        mbinteractable
                        -- if no choice or it was already chosen before it doesnt check
                        -- and doesnt make any alteration
                    else if (playerChoice == cOptionData.valueToMatch) then
                        Just (Item { idata | writtenContent = Just choiceStr })
                            |> createAttributeIfNotExistsAndOrSetValue (Astring playerChoice) "chosenOption"
                            |> createAttributeIfNotExistsAndOrSetValue (ADictStringString cOptionData.successTextDict) "additionalTextDict"
                            |> createAttributesIfNotExistsAndOrSetValue cOptionData.lnewAttrs
                            |> removeAttributeIfExists "answerOptionsList"
                    else
                        mbinteractable

                --debugStr = "player choice is " ++ playerChoice ++ "  , successTextDict is " ++ (toString successTextDict)
                --           ++ "  ,  valueTomatch is " ++ valueToMatch
                --_ = Debug.log "debug checkIfChosenOptionIs in Engine.manifest was executed  : " debugStr
            in
                theMbInteractable

        Nothing ->
            Nothing

        _ ->
            mbinteractable
                |> writeInteractionIncident "error" "Trying to use checkIfAnswerCorrect function with an interactable that is not an Item ! "


{-| This change should only be used in conjunction with isChosenOptionEqualTo as a condition
if that condition is verified we know that playerChoice is equal to matchedValue and we can just call
checkAndActIfChosenOptionIs
-}
processChosenOptionEqualTo : CheckOptionData -> Maybe Interactable -> Maybe Interactable
processChosenOptionEqualTo cOptionData mbinteractable =
    checkAndActIfChosenOptionIs cOptionData.valueToMatch cOptionData mbinteractable


moveCharacterToLocation : String -> Maybe Interactable -> Maybe Interactable
moveCharacterToLocation locationId mbInteractable =
    case mbInteractable of
        Just (Character cdata) ->
            -- still have to check if location exists
            Just (Character { cdata | characterPlacement = CharacterInLocation locationId })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveCharacterToLocation function with an interactable that is not a Character ! "


moveCharacterOffScreen : Maybe Interactable -> Maybe Interactable
moveCharacterOffScreen mbInteractable =
    case mbInteractable of
        Just (Character cdata) ->
            Just (Character { cdata | characterPlacement = CharacterOffScreen })

        Nothing ->
            Nothing

        _ ->
            mbInteractable
                |> writeInteractionIncident "error" "Trying to use moveCharacterOffScreen function with an interactable that is not a Character ! "


itemIsInInventory : String -> Manifest -> Bool
itemIsInInventory id manifest =
    getItemsInInventory manifest
        |> List.any ((==) id)


itemIsCorrectlyAnswered : String -> Manifest -> Bool
itemIsCorrectlyAnswered id manifest =
    attrValueIsEqualTo (Abool True) "isCorrectlyAnswered" id manifest


{-| This includes both the cases when Item is IncorrectlyAnswered or NotAnswered
-}
itemIsNotCorrectlyAnswered : String -> Manifest -> Bool
itemIsNotCorrectlyAnswered id manifest =
    not (itemIsCorrectlyAnswered id manifest)


itemIsIncorrectlyAnswered : String -> Manifest -> Bool
itemIsIncorrectlyAnswered id manifest =
    attrValueIsEqualTo (Abool True) "isIncorrectlyAnswered" id manifest


itemIsNotAnswered : String -> Manifest -> Bool
itemIsNotAnswered id manifest =
    (not (itemIsCorrectlyAnswered id manifest)) && (not (itemIsIncorrectlyAnswered id manifest))


characterIsInLocation : String -> String -> Manifest -> Bool
characterIsInLocation character currentLocation manifest =
    getCharactersInLocation currentLocation manifest
        |> List.any ((==) character)


itemIsInLocation : String -> String -> Manifest -> Bool
itemIsInLocation item currentLocation manifest =
    getItemsInLocation currentLocation manifest
        |> List.any ((==) item)


itemIsNotInLocation : String -> String -> Manifest -> Bool
itemIsNotInLocation item currentLocation manifest =
    not (itemIsInLocation item currentLocation manifest)


itemIsOffScreen : String -> Manifest -> Bool
itemIsOffScreen id manifest =
    case (Dict.get id manifest) of
        Just interactable ->
            case interactable of
                Item idata ->
                    if (idata.itemPlacement == ItemOffScreen) then
                        True
                    else
                        False

                _ ->
                    False

        Nothing ->
            False


itemIsInAnyLocationOrInventory : String -> Manifest -> Bool
itemIsInAnyLocationOrInventory id manifest =
    case (Dict.get id manifest) of
        Just interactable ->
            case interactable of
                Item idata ->
                    case idata.itemPlacement of
                        ItemInInventory ->
                            True

                        ItemInLocation locid ->
                            True

                        ItemOffScreen ->
                            False

                _ ->
                    False

        Nothing ->
            False


counterExists : String -> String -> Manifest -> Bool
counterExists counterId interId manifest =
    let
        helperFunc : String -> { a | attributes : Dict String AttrTypes } -> Bool
        helperFunc theCounterId dataRecord =
            case (Dict.get ("counter_" ++ theCounterId) dataRecord.attributes) of
                Nothing ->
                    False

                Just val ->
                    True
    in
        case (Dict.get interId manifest) of
            Just (Item idata) ->
                helperFunc counterId idata

            Just (Character cdata) ->
                helperFunc counterId cdata

            Just (Location ldata) ->
                helperFunc counterId ldata

            Nothing ->
                False


counterLessThen : Int -> String -> String -> Manifest -> Bool
counterLessThen val counterId interId manifest =
    let
        helperFunc : String -> { a | attributes : Dict String AttrTypes } -> Bool
        helperFunc theCounterId dataRecord =
            case (Dict.get ("counter_" ++ theCounterId) dataRecord.attributes) of
                Nothing ->
                    False

                Just attrvalue ->
                    case attrvalue of
                        AnInt value ->
                            if (value < val) then
                                True
                            else
                                False

                        _ ->
                            False
    in
        case (Dict.get interId manifest) of
            Just (Item idata) ->
                helperFunc counterId idata

            Just (Character cdata) ->
                helperFunc counterId cdata

            Just (Location ldata) ->
                helperFunc counterId ldata

            Nothing ->
                False


counterGreaterThenOrEqualTo : Int -> String -> String -> Manifest -> Bool
counterGreaterThenOrEqualTo val counterId interId manifest =
    (counterExists counterId interId manifest)
        && (not (counterLessThen val counterId interId manifest))


getCounterValue : String -> String -> Manifest -> Maybe Int
getCounterValue counterId interId manifest =
    Dict.get interId manifest
        |> getICounterValue counterId


{-| similar to getCounterValue but takes as arg a maybe Interactable instead of an interactableId
-}
getICounterValue : String -> Maybe Interactable -> Maybe Int
getICounterValue counterId mbInteractable =
    case (mbInteractable) of
        Just (Item idata) ->
            Dict.get ("counter_" ++ counterId) idata.attributes
                |> convertMbAttrTypeToMbInt

        Just (Character cdata) ->
            Dict.get ("counter_" ++ counterId) cdata.attributes
                |> convertMbAttrTypeToMbInt

        Just (Location ldata) ->
            Dict.get ("counter_" ++ counterId) ldata.attributes
                |> convertMbAttrTypeToMbInt

        Nothing ->
            Nothing


convertMbAttrTypeToMbInt : Maybe AttrTypes -> Maybe Int
convertMbAttrTypeToMbInt mbanint =
    case mbanint of
        Nothing ->
            Nothing

        Just val ->
            case val of
                AnInt ival ->
                    Just ival

                _ ->
                    Nothing


attrValueIsEqualTo : AttrTypes -> String -> String -> Manifest -> Bool
attrValueIsEqualTo attrValue attrId interactableId manifest =
    case (Dict.get interactableId manifest) of
        Nothing ->
            False

        Just interactable ->
            case interactable of
                Item idata ->
                    if (Dict.get attrId idata.attributes == Just attrValue) then
                        True
                    else
                        False

                Character cdata ->
                    if (Dict.get attrId cdata.attributes == Just attrValue) then
                        True
                    else
                        False

                Location ldata ->
                    if (Dict.get attrId ldata.attributes == Just attrValue) then
                        True
                    else
                        False



{- sets attribute value only if attribute was previously created -}


setAttributeValue : AttrTypes -> String -> Maybe Interactable -> Maybe Interactable
setAttributeValue attrValue attrId mbinteractable =
    let
        getNewDataRecord : AttrTypes -> String -> { a | attributes : Dict String AttrTypes } -> { a | attributes : Dict String AttrTypes }
        getNewDataRecord theattrValue theattrId dataRecord =
            let
                newAttributes =
                    case Dict.get theattrId dataRecord.attributes of
                        Nothing ->
                            dataRecord.attributes

                        Just val ->
                            Dict.update theattrId (\_ -> Just theattrValue) dataRecord.attributes

                newDataRecord =
                    { dataRecord | attributes = newAttributes }
            in
                newDataRecord
    in
        case mbinteractable of
            Just (Item idata) ->
                Just (Item <| getNewDataRecord attrValue attrId idata)

            Just (Character cdata) ->
                Just (Character <| getNewDataRecord attrValue attrId cdata)

            Just (Location ldata) ->
                Just (Location <| getNewDataRecord attrValue attrId ldata)

            Nothing ->
                Nothing


createAttributeIfNotExistsAndOrSetValue : AttrTypes -> String -> Maybe Interactable -> Maybe Interactable
createAttributeIfNotExistsAndOrSetValue theVal attrId mbinteractable =
    createAttributeIfNotExists theVal attrId mbinteractable
        |> setAttributeValue theVal attrId



{- tries to create and or set the value of several attributes on the interactable given by the list of tuples
   first element of tuple is attribute id and second is the attribute value
-}


createAttributesIfNotExistsAndOrSetValue : List ( String, AttrTypes ) -> Maybe Interactable -> Maybe Interactable
createAttributesIfNotExistsAndOrSetValue ltupattrs mbinteractable =
    case ltupattrs of
        [] ->
            mbinteractable

        head :: rest ->
            createAttributeIfNotExistsAndOrSetValue (Tuple.second head) (Tuple.first head) mbinteractable
                |> createAttributesIfNotExistsAndOrSetValue rest


createOrSetAttributeValueFromOtherInterAttr : String -> String -> String -> Manifest -> Maybe Interactable -> Maybe Interactable
createOrSetAttributeValueFromOtherInterAttr attrId otherInterAtrrId otherInterId manifest mbinteractable =
    let
        mbAttrVal =
            getInteractableAttribute otherInterAtrrId (Dict.get otherInterId manifest)
    in
        -- if the attribute doesnt exist in the other interactable it doesn't create or set any attribute
        case mbAttrVal of
            Just theAttrVal ->
                createAttributeIfNotExistsAndOrSetValue theAttrVal attrId mbinteractable

            Nothing ->
                mbinteractable
                    |> writeInteractionIncident "warning" ("Trying to use createOrSetAttributeValueFromOtherInterAttr function but attribute in other interactable doesnt exist ( or other interactable doesnt exist ) ! attributeId : " ++ attrId ++ " , otherInteractableId : " ++ otherInterId)


removeAttributeIfExists : String -> Maybe Interactable -> Maybe Interactable
removeAttributeIfExists attrId mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            let
                newAttributes =
                    Dict.remove attrId idata.attributes
            in
                Just (Item { idata | attributes = newAttributes })

        Just (Character cdata) ->
            let
                newAttributes =
                    Dict.remove attrId cdata.attributes
            in
                Just (Character { cdata | attributes = newAttributes })

        Just (Location ldata) ->
            let
                newAttributes =
                    Dict.remove attrId ldata.attributes
            in
                Just (Location { ldata | attributes = newAttributes })

        Nothing ->
            mbinteractable
                |> writeInteractionIncident "error" ("Trying to remove attribute from  interactable that doesnt exist ")


getInteractableAttribute : String -> Maybe Interactable -> Maybe AttrTypes
getInteractableAttribute attrId mbinteractable =
    case mbinteractable of
        Just (Item idata) ->
            Dict.get attrId idata.attributes

        Just (Character cdata) ->
            Dict.get attrId cdata.attributes

        Just (Location ldata) ->
            Dict.get attrId ldata.attributes

        _ ->
            Nothing


getReservedAttrIds : List String
getReservedAttrIds =
    [ "playerAnswer"
    , "isCorrectlyAnswered"
    , "isIncorrectlyAnswered"
    , "narrativeHeader"
    , "additionalTextDict"
    , "chosenOption"
    , "answerOptionsList"
    ]


comparesEqual : String -> String -> Types.AnswerCase -> Types.AnswerSpaces -> Bool
comparesEqual str1 str2 ansCase ansSpaces =
    let
        ( str1_, str2_ ) =
            if ansCase == CaseInsensitiveAnswer then
                ( String.toLower str1, String.toLower str2 )
            else
                ( str1, str2 )

        ( str1Alt, str2Alt ) =
            if ansSpaces == AnswerSpacesDontMatter then
                ( eliminateAllWhiteSpaces str1_, eliminateAllWhiteSpaces str2_ )
            else
                ( str1_, str2_ )
    in
        if (str1Alt == str2Alt) then
            True
        else
            False


comparesEqualToAtLeastOne : String -> List String -> Types.AnswerCase -> Types.AnswerSpaces -> Bool
comparesEqualToAtLeastOne str1 lstrs ansCase ansSpaces =
    List.map (\x -> comparesEqual str1 x ansCase ansSpaces) lstrs
        |> List.filter (\x -> x == True)
        |> List.isEmpty
        |> not


eliminateAllWhiteSpaces : String -> String
eliminateAllWhiteSpaces theStr =
    Regex.replace Regex.All (Regex.regex " ") (\_ -> "") theStr
