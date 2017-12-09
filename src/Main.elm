port module Main exposing (..)

import Engine exposing (..)
import Types as EngineTypes exposing (BackendAnswerStatus(..), AnswerInfo, InteractionExtraInfo, MoreInfoNeeded(..))
import OurStory2.Manifest as Manifest
import OurStory2.Rules as Rules
import OurStory2.Narrative as Narrative
import Html exposing (..)
import Html.Attributes exposing (..)
import Tuple
import Theme.Layout
import Theme.AnswerBox as AnswerBox exposing (init, Model)
import Theme.Settings as Settings
import Theme.StartScreen
import Theme.EndScreen
import ClientTypes exposing (..)


--import Audio

import Components exposing (..)
import Dict exposing (Dict)
import List.Zipper as Zipper exposing (Zipper)
import Json.Decode
import Json.Decode.Pipeline
import Geolocation
import Task
import TranslationHelper exposing (getInLanguage)
import TypeConverterHelper as Tconverter exposing (..)
import GpsUtils exposing (..)
import SomeTests
import Http
import Regex
import Update.Extra
import InfoForBkendApiRequests


{- This is the kernel of the whole app.  It glues everything together and handles some logic such as choosing the correct narrative to display.
   You shouldn't need to change anything in this file, unless you want some kind of different behavior.
-}
-- MODEL


type alias Model =
    { engineModel : Engine.Model
    , debugMode : Bool
    , baseImgUrl : String
    , baseSoundUrl : String
    , itemsLocationsAndCharacters : List Components.Entity
    , playerName : String
    , answerBoxModel : AnswerBox.Model
    , settingsModel : Settings.Model
    , mbSentText : Maybe String
    , alertMessages : List String
    , geoLocation : Maybe Engine.GeolocationInfo
    , geoDistances : List ( String, Float )
    , defaultZoneRadius : Float
    , bkendAnswerStatusDict : Dict String EngineTypes.BackendAnswerStatus
    , loaded : Bool
    , languageStoryLines : Dict String (List StorySnippet)
    , languageNarrativeContents : Dict String (Dict String (Zipper String))
    , languageAudioContents : Dict String (Dict String ClientTypes.AudioFileInfo)
    , displayStartScreen : Bool
    , startScreenInfo : StartScreenInfo
    , displayEndScreen : Bool
    , endScreenInfo : EndScreenInfo
    }


init : Flags -> ( Model, Cmd ClientTypes.Msg )
init flags =
    let
        dictEntities =
            Rules.rules

        ( engineModel, lincidents ) =
            Engine.init
                { items = List.map Tuple.first Manifest.items
                , locations = List.map Tuple.first Manifest.locations
                , characters = List.map Tuple.first Manifest.characters
                }
                Narrative.initialChoiceLanguages
                (Dict.map (curry getRuleData) dictEntities)
                |> Engine.changeWorld Rules.startingState

        answerboxmodel =
            AnswerBox.init

        settingsmodel =
            Settings.init Narrative.initialChoiceLanguages

        displaylanguage =
            settingsmodel.displayLanguage

        startLincidents =
            [ ( "startingState ", lincidents ) ]

        allPossibleIncidentsAboutCwcmds =
            SomeTests.getAllPossibleIncidentsAboutCwcmds engineModel startLincidents

        debugMode_ =
            False
    in
        ( { engineModel = engineModel
          , debugMode = debugMode_
          , baseImgUrl = flags.baseImgUrl
          , baseSoundUrl = flags.baseSoundUrl
          , itemsLocationsAndCharacters = (Manifest.items ++ Manifest.locations ++ Manifest.characters)
          , playerName = "___investigator___" -- default
          , answerBoxModel = answerboxmodel
          , settingsModel = settingsmodel
          , mbSentText = Nothing
          , alertMessages =
                if debugMode_ then
                    allPossibleIncidentsAboutCwcmds
                else
                    []
          , geoLocation = Nothing
          , geoDistances = []
          , defaultZoneRadius = 50.0
          , bkendAnswerStatusDict =
                (Manifest.items ++ Manifest.locations ++ Manifest.characters)
                    |> List.map Tuple.first
                    |> List.map (\interactableId -> ( interactableId, EngineTypes.NoInfoYet ))
                    |> Dict.fromList

          --, loaded = False
          , loaded = True
          , languageStoryLines = Narrative.startingNarratives

          -- dictionary that associates ruleIds to a dict languageId (narrative : ZipperString)
          , languageNarrativeContents = Dict.map (curry getLanguagesNarrativeDict) dictEntities
          , languageAudioContents = Dict.map (curry getLanguagesAudioDict) dictEntities
          , displayStartScreen = True
          , startScreenInfo = Narrative.startScreenInfo
          , displayEndScreen = False
          , endScreenInfo = Narrative.endScreenInfo
          }
        , Cmd.none
        )


findEntity : Model -> String -> Entity
findEntity model id =
    model.itemsLocationsAndCharacters
        |> List.filter (Tuple.first >> (==) id)
        |> List.head
        |> Maybe.withDefault (entity id)



-- UPDATE


update :
    ClientTypes.Msg
    -> Model
    -> ( Model, Cmd ClientTypes.Msg )
update msg model =
    case Engine.hasFreezingEnd model.engineModel of
        True ->
            -- no-op if story has ended and it has a FreezingType End
            ( model, Cmd.none )

        False ->
            -- if it hasn't ended or the endtype is not a freezingend
            case msg of
                StartMainGame ->
                    ( { model | displayStartScreen = False }, Cmd.none )

                StartMainGameNewPlayerName playerNameStr ->
                    if playerNameStr /= "" then
                        let
                            newPlayerOneEntity =
                                findEntity model "playerOne"
                                    |> Components.updateAllLgsDisplayName playerNameStr

                            newEntities =
                                model.itemsLocationsAndCharacters
                                    |> List.map
                                        (\x ->
                                            if ((Tuple.first x) == "playerOne") then
                                                newPlayerOneEntity
                                            else
                                                x
                                        )

                            newAnswerBoxModel =
                                AnswerBox.update "" model.answerBoxModel

                            newModel =
                                { model
                                    | itemsLocationsAndCharacters = newEntities
                                    , playerName = playerNameStr
                                    , answerBoxModel = newAnswerBoxModel
                                }
                        in
                            update StartMainGame newModel
                    else
                        update StartMainGame model

                InteractSendingText interactableId theText ->
                    let
                        --clear the Text Box
                        newAnswerBoxModel =
                            AnswerBox.update "" model.answerBoxModel

                        newModel =
                            { model
                                | mbSentText = Just (String.trim theText)
                                , answerBoxModel = newAnswerBoxModel
                            }
                    in
                        update (Interact interactableId) newModel

                Interact interactableId ->
                    let
                        needCoords =
                            findEntity model interactableId |> getNeedsGpsCoords

                        mbGpsZone =
                            findEntity model interactableId |> getNeedsToBeInGpsZone

                        needsToBeInZone =
                            (Maybe.withDefault False (Maybe.map .needsToBeIn mbGpsZone))
                                && not model.settingsModel.dontNeedToBeInZone

                        interactionExtraInfo =
                            getExtraInfoFromModel model interactableId

                        nModel =
                            { model
                                | alertMessages = []
                                , mbSentText = Nothing
                            }

                        ( newModel, cmds ) =
                            if (needCoords && not needsToBeInZone) then
                                ( nModel, getNewCoords interactableId Nothing False interactionExtraInfo )
                            else if (needsToBeInZone) then
                                ( nModel, getNewCoords interactableId mbGpsZone True interactionExtraInfo )
                            else
                                update (InteractStepTwo interactableId interactionExtraInfo) nModel
                    in
                        ( newModel, cmds )

                NewCoordsForInterId interactableId mbGpsZone needsToBeInZone interactionExtraInfo (Ok location) ->
                    let
                        theDistance =
                            getDistance location mbGpsZone

                        distanceToClosestLocations =
                            Manifest.locations
                                |> List.map (getDictLgNamesAndCoords [ model.settingsModel.displayLanguage ])
                                |> List.map (Dict.get model.settingsModel.displayLanguage)
                                |> GpsUtils.getDistancesTo 1000 location

                        inDistance =
                            checkIfInDistance mbGpsZone theDistance model.defaultZoneRadius

                        newModel =
                            { model
                                | geoLocation = Just location
                                , geoDistances = distanceToClosestLocations
                            }

                        updatedInteractionExtraInfo =
                            updateInterExtraInfoWithGeoInfo interactionExtraInfo model
                    in
                        if (not needsToBeInZone || (needsToBeInZone && inDistance)) then
                            update (InteractStepTwo interactableId updatedInteractionExtraInfo) newModel
                        else
                            update (NotInTheZone interactableId mbGpsZone location theDistance) newModel

                NewCoordsForInterId interactableId mbGpsZone needsToBeInZone interactionExtraInfo (Err err) ->
                    let
                        newModel =
                            { model
                                | geoLocation = Nothing
                                , geoDistances = []
                                , alertMessages = [ "Failed to get gps coordinates" ]
                            }

                        updatedInteractionExtraInfo =
                            updateInterExtraInfoWithGeoInfo interactionExtraInfo model
                    in
                        if (not needsToBeInZone) then
                            update (InteractStepTwo interactableId updatedInteractionExtraInfo) newModel
                        else
                            ( newModel, Cmd.none )

                NotInTheZone interactableId mbGpsZone location theDistance ->
                    let
                        zoneCoordsStr =
                            getMbGpsZoneLatLon mbGpsZone
                                --|> Maybe.map toString
                                |> Maybe.map GpsUtils.convertDecimalTupleToGps
                                |> Maybe.withDefault ""

                        theName =
                            findEntity model interactableId
                                |> getSingleLgDisplayInfo model.settingsModel.displayLanguage
                                |> .name

                        linfoStr =
                            [ " Trying to move to  " ++ theName ++ " failed . "
                            , "you're not close enough."
                            , "You are at : " ++ GpsUtils.convertDecimalTupleToGps ( location.latitude, location.longitude )
                            , "Please move closer to " ++ zoneCoordsStr
                            , "Your distance to where you should be is : "
                                ++ toString (round theDistance)
                                ++ " meters"
                            ]

                        newModel =
                            { model | alertMessages = linfoStr }
                    in
                        ( newModel, Cmd.none )

                InteractStepTwo interactableId interactionExtraInfo ->
                    -- only allow interaction if this interactable isnt waiting for some backend answer confirmation
                    if (Dict.get interactableId model.bkendAnswerStatusDict == Just EngineTypes.WaitingForInfoRequested) then
                        -- Interactable is awaiting for some backend confirmation. No interaction possible at this time
                        ( { model | alertMessages = "Please Wait ... \n" :: model.alertMessages }, Cmd.none )
                    else
                        let
                            ( newEngineModel, maybeMatchedRuleId, lInteractionIncidents, infoNeeded ) =
                                Engine.update
                                    interactableId
                                    interactionExtraInfo
                                    model.engineModel

                            newModel =
                                { model | engineModel = newEngineModel }

                            newInteractionExtraInfo =
                                { interactionExtraInfo | mbMatchedRuleId = maybeMatchedRuleId }

                            getTheUrl strUrl =
                                strUrl ++ Maybe.withDefault "" interactionExtraInfo.mbInputTextForBackend ++ "/"

                            interactionIncidents =
                                if model.debugMode then
                                    lInteractionIncidents
                                else
                                    []
                        in
                            case infoNeeded of
                                NoInfoNeeded ->
                                    update (InteractStepThree interactableId newInteractionExtraInfo)
                                        { newModel
                                            | bkendAnswerStatusDict = Dict.update interactableId (\x -> Just EngineTypes.NoInfoYet) model.bkendAnswerStatusDict
                                            , alertMessages = interactionIncidents
                                        }

                                AnswerInfoToQuestionNeeded strUrl ->
                                    if interactionExtraInfo.bkAnsStatus == NoInfoYet then
                                        let
                                            -- clear the text box so the text can't be used by any other interactable.
                                            newAnswerBoxModel =
                                                AnswerBox.update "" model.answerBoxModel

                                            newInteractionExtraInfoTwo =
                                                { newInteractionExtraInfo | bkAnsStatus = EngineTypes.WaitingForInfoRequested }
                                        in
                                            ( { newModel
                                                | bkendAnswerStatusDict = Dict.update interactableId (\x -> Just EngineTypes.WaitingForInfoRequested) model.bkendAnswerStatusDict
                                                , alertMessages = [ "___Checking_Answer___" ]
                                                , answerBoxModel = newAnswerBoxModel
                                              }
                                            , getBackendAnswerInfo interactableId newInteractionExtraInfoTwo (getTheUrl strUrl)
                                            )
                                    else
                                        ( model, Cmd.none )

                AnswerChecked interactableId interactionExtraInfo (Ok bresp) ->
                    let
                        nModel =
                            { model
                                | bkendAnswerStatusDict = Dict.update interactableId (\val -> Just (EngineTypes.Ans bresp)) model.bkendAnswerStatusDict
                                , alertMessages = []
                            }

                        nInteractionExtraInfo =
                            { interactionExtraInfo | bkAnsStatus = Ans bresp }

                        ( newInteractionExtraInfo2, newModel2 ) =
                            getNewModelAndInteractionExtraInfoByEngineUpdate interactableId nInteractionExtraInfo nModel
                    in
                        --update (InteractStepTwo interactableId newInteractionExtraInfo) newModel
                        update (InteractStepThree interactableId newInteractionExtraInfo2) newModel2

                AnswerChecked interactableId interactionExtraInfo (Err error) ->
                    let
                        nModel =
                            { model
                                | bkendAnswerStatusDict = Dict.update interactableId (\val -> Just CommunicationFailure) model.bkendAnswerStatusDict
                                , alertMessages = [ "___Couldnt_check_Answer___" ]
                            }

                        nInteractionExtraInfo =
                            { interactionExtraInfo | bkAnsStatus = CommunicationFailure }

                        ( newInteractionExtraInfo2, newModel2 ) =
                            getNewModelAndInteractionExtraInfoByEngineUpdate interactableId nInteractionExtraInfo nModel
                    in
                        --update (InteractStepTwo interactableId newInteractionExtraInfo) newModel
                        update (InteractStepThree interactableId newInteractionExtraInfo2) newModel2

                InteractStepThree interactableId interactionExtraInfo ->
                    let
                        maybeMatchedRuleId =
                            interactionExtraInfo.mbMatchedRuleId

                        displayLanguage =
                            model.settingsModel.displayLanguage

                        newEngineModel =
                            model.engineModel

                        {- Helper function  called by narrativesForThisInteraction -}
                        getTheNarrativeHeader languageId =
                            Engine.getInteractableAttribute "narrativeHeader" interactableId newEngineModel
                                |> Tconverter.mbAttributeToString model.debugMode
                                |> String.split " "
                                |> List.map (\x -> getInLanguage languageId x)
                                |> String.join " "

                        {- Helper function called by  narrativesForThisInteraction -}
                        getTheWrittenContent languageId =
                            Engine.getItemWrittenContent interactableId newEngineModel
                                |> Maybe.withDefault ""
                                |> String.split " "
                                |> List.map (\x -> getInLanguage languageId x)
                                |> String.join " "

                        {- Helper function called by  narrativesForThisInteraction -}
                        isLastZip : Zipper String -> Bool
                        isLastZip val =
                            if (Zipper.next val == Nothing) then
                                True
                            else
                                False

                        additionalTextDict =
                            -- additionalTextDict
                            Engine.getInteractableAttribute "additionalTextDict" interactableId model.engineModel
                                |> Tconverter.mbAttributeToDictStringString model.debugMode

                        {- Helper function called by  narrativesForThisInteraction -}
                        wrapWithHeaderWrittenContentAndAdditionalText : String -> String -> String
                        wrapWithHeaderWrittenContentAndAdditionalText lgId mainContent =
                            getTheNarrativeHeader lgId
                                ++ ("\n" ++ mainContent)
                                ++ ("\n" ++ getTheWrittenContent lgId)
                                ++ "  \n"
                                ++ (Dict.get lgId additionalTextDict |> Maybe.withDefault "")

                        temporaryHackToSubstitueImgUrl : String -> String -> String
                        temporaryHackToSubstitueImgUrl baseImgUrl theStr =
                            if baseImgUrl /= "" then
                                Regex.replace Regex.All (Regex.regex "\\(img\\/") (\_ -> "(" ++ baseImgUrl) theStr
                            else
                                theStr

                        mbsuggestInteractionId : Maybe String
                        mbsuggestInteractionId =
                            Engine.getInteractableAttribute "suggestedInteraction" interactableId model.engineModel
                                |> Tconverter.mbAttributeToMbString model.debugMode

                        {- If the engine found a matching rule, look up the narrative content component for that rule if possible.  The description from the display info component for the entity that was interacted with is used as a default. -}
                        narrativesForThisInteraction =
                            { interactableNames = findEntity model interactableId |> getDictLgNames (Narrative.desiredLanguages)
                            , interactableCssSelector = findEntity model interactableId |> getClassName
                            , narratives =
                                -- is a Dict String (String , Bool)
                                let
                                    dict1 =
                                        (maybeMatchedRuleId
                                            |> Maybe.andThen (\ruleId -> Dict.get ruleId model.languageNarrativeContents)
                                            |> Maybe.withDefault Dict.empty
                                            |> Dict.map
                                                (\lgId val ->
                                                    ( Zipper.current val
                                                        |> temporaryHackToSubstitueImgUrl model.baseImgUrl
                                                        |> wrapWithHeaderWrittenContentAndAdditionalText lgId
                                                    , isLastZip val
                                                    )
                                                )
                                        )

                                    dict2 =
                                        findEntity model interactableId
                                            |> getDictLgDescriptions (Narrative.desiredLanguages)
                                            |> Dict.map (\lgId val -> ( wrapWithHeaderWrittenContentAndAdditionalText lgId val, True ))
                                in
                                    Components.mergeDicts dict2 dict1
                            , audios =
                                maybeMatchedRuleId
                                    |> Maybe.andThen (\ruleId -> Dict.get ruleId model.languageAudioContents)
                                    |> Maybe.withDefault Dict.empty
                                    |> Dict.map (\lgId val -> { val | fileName = model.baseSoundUrl ++ val.fileName })
                            , mbSuggestedInteractionId = mbsuggestInteractionId
                            , suggestedInteractionNameDict =
                                if mbsuggestInteractionId /= Nothing then
                                    findEntity model (Maybe.withDefault "" mbsuggestInteractionId) |> getDictLgNames (Narrative.desiredLanguages)
                                else
                                    Dict.empty
                            }

                        {- If a rule matched, attempt to move to the next associated narrative content for next time.
                           This is a helper function used in updateNarrativeLgsDict in a Dict.map
                        -}
                        updateNarrativeContent : Maybe (Zipper String) -> Maybe (Zipper String)
                        updateNarrativeContent =
                            Maybe.map (\narrative -> Zipper.next narrative |> Maybe.withDefault narrative)

                        {- If a rule matched, attempt to move to the next associated narrative content for next time.
                           This is a helper function used by  Dict.update in updatedContent
                        -}
                        updateNarrativeLgsDict : Maybe (Dict String (Zipper String)) -> Maybe (Dict String (Zipper String))
                        updateNarrativeLgsDict mbDict =
                            case mbDict of
                                Just dict ->
                                    Dict.map (\lgid val -> updateNarrativeContent (Just val) |> Maybe.withDefault val) dict
                                        |> Just

                                Nothing ->
                                    Nothing

                        {- If a rule matched, attempt to move to the next associated narrative content for next time. -}
                        updatedContent =
                            maybeMatchedRuleId
                                |> Maybe.map (\id -> Dict.update id updateNarrativeLgsDict model.languageNarrativeContents)
                                |> Maybe.withDefault model.languageNarrativeContents

                        {- Helper function called by  newLanguageStoryLines -}
                        mergeToDictStoryLine : ( String, StorySnippet ) -> Dict String (List StorySnippet) -> Dict String (List StorySnippet)
                        mergeToDictStoryLine tup storyLinesDict =
                            let
                                languageId =
                                    Tuple.first tup

                                mbExistingStorySnippets =
                                    Dict.get languageId storyLinesDict

                                newStorySnippet =
                                    Tuple.second tup

                                mbNewval =
                                    Just (newStorySnippet :: (Maybe.withDefault [] mbExistingStorySnippets))
                            in
                                Dict.update languageId (\mbval -> mbNewval) storyLinesDict

                        {- updates the languages StoryLines dict with the narrative contents ( in several languages )
                           for this interaction
                        -}
                        newLanguageStoryLines =
                            let
                                nfti =
                                    narrativesForThisInteraction

                                llgssnippets =
                                    Dict.keys narrativesForThisInteraction.narratives
                                        |> List.map
                                            (\lgId ->
                                                ( lgId
                                                , { interactableName =
                                                        Dict.get lgId nfti.interactableNames
                                                            |> Maybe.withDefault (Maybe.withDefault "noName" (Dict.get "en" nfti.interactableNames))
                                                  , interactableId = interactableId
                                                  , isWritable =
                                                        (Engine.isWritable interactableId model.engineModel
                                                            && (interactionExtraInfo.currentLocation
                                                                    == Engine.getCurrentLocation model.engineModel
                                                               )
                                                        )
                                                  , interactableCssSelector = nfti.interactableCssSelector
                                                  , narrative =
                                                        (Dict.get lgId nfti.narratives)
                                                            |> Maybe.map Tuple.first
                                                            |> Maybe.withDefault ""
                                                  , mbAudio = Dict.get lgId nfti.audios
                                                  , mbSuggestedInteractionId = nfti.mbSuggestedInteractionId
                                                  , mbSuggestedInteractionName = Dict.get lgId nfti.suggestedInteractionNameDict
                                                  , isLastInZipper =
                                                        (Dict.get lgId nfti.narratives)
                                                            |> Maybe.map Tuple.second
                                                            |> Maybe.withDefault True
                                                  }
                                                )
                                            )
                            in
                                List.foldl (\x y -> mergeToDictStoryLine x y) model.languageStoryLines llgssnippets

                        -- after an interaction clear the TextBox
                        newAnswerBoxModel =
                            AnswerBox.update "" model.answerBoxModel

                        getAlertMessage1 =
                            case (Dict.get displayLanguage narrativesForThisInteraction.narratives) of
                                Nothing ->
                                    [ "No narrative content for this interaction in the current language. Maybe you want to try channging language !" ]

                                _ ->
                                    []

                        getAlertMessage2 =
                            Engine.getInteractableAttribute "warningMessage" interactableId model.engineModel
                                |> Tconverter.mbAttributeToDictStringString model.debugMode
                                |> Dict.get displayLanguage
                                |> Maybe.withDefault ""
                                |> (\x ->
                                        if x /= "" then
                                            (x :: [])
                                        else
                                            []
                                   )

                        --updateChoiceLanguages
                        newSettingsModel =
                            Settings.update (ClientTypes.SetAvailableLanguages (getChoiceLanguages newEngineModel)) model.settingsModel

                        -- check if ended
                        hasEnded =
                            Engine.getInteractableAttribute "gameHasEnded" "gameStateItem" model.engineModel
                                |> Tconverter.mbAttributeToBool model.debugMode

                        newSettingsModel2 =
                            if (hasEnded && not model.settingsModel.showExitToFinalScreenButton) then
                                Settings.update (ClientTypes.SettingsShowExitToFinalScreenButton) newSettingsModel
                            else
                                newSettingsModel
                    in
                        ( { model
                            | engineModel = newEngineModel --  |> checkEnd
                            , alertMessages = (getAlertMessage1 ++ getAlertMessage2)
                            , answerBoxModel = newAnswerBoxModel
                            , languageStoryLines = newLanguageStoryLines
                            , languageNarrativeContents = updatedContent
                            , settingsModel = newSettingsModel2
                          }
                        , Cmd.none
                        )

                NewUserSubmitedText theText ->
                    let
                        newAnswerBoxModel =
                            AnswerBox.update theText model.answerBoxModel
                    in
                        ( { model | answerBoxModel = newAnswerBoxModel }, Cmd.none )

                ChangeOptionDisplayLanguage theLanguage ->
                    let
                        newSettingsModel =
                            Settings.update (ClientTypes.SetDisplayLanguage theLanguage) model.settingsModel
                    in
                        ( { model | settingsModel = newSettingsModel }, Cmd.none )

                ChangeOptionDontCheckGps bdontcheck ->
                    let
                        newSettingsModel =
                            Settings.update (ClientTypes.SetDontNeedToBeInZone bdontcheck) model.settingsModel
                    in
                        ( { model | settingsModel = newSettingsModel }, Cmd.none )

                CloseAlert ->
                    ( { model | alertMessages = [] }, Cmd.none )

                ChangeOptionAudioAutoplay bautoplay ->
                    let
                        newSettingsModel =
                            Settings.update (ClientTypes.SettingsChangeOptionAutoplay bautoplay) model.settingsModel
                    in
                        ( { model | settingsModel = newSettingsModel }, Cmd.none )

                LayoutWithSideBar bWithSidebar ->
                    let
                        newSettingsModel =
                            Settings.update (ClientTypes.SettingsLayoutWithSidebar bWithSidebar) model.settingsModel
                    in
                        ( { model | settingsModel = newSettingsModel }, Cmd.none )

                ToggleShowExpandedSettings ->
                    let
                        newSettingsModel =
                            Settings.update (ClientTypes.SettingsToggleShowExpanded) model.settingsModel
                    in
                        ( { model | settingsModel = newSettingsModel }, Cmd.none )

                ToggleShowHideSaveLoadBtns ->
                    let
                        newSettingsModel =
                            Settings.update (ClientTypes.SettingsToggleShowHideSaveLoadBtns) model.settingsModel
                    in
                        ( { model | settingsModel = newSettingsModel }, Cmd.none )

                SaveHistory ->
                    saveHistoryToStorageHelper model

                RequestForStoredHistory ->
                    ( model, sendRequestForStoredHistory "" )

                LoadHistory obj ->
                    let
                        playerName =
                            obj.playerName

                        newlist =
                            convertToListIdExtraInfo obj.lInteractions

                        savedSettings =
                            model.settingsModel

                        ( newModel, cmds ) =
                            init (Flags model.baseImgUrl model.baseSoundUrl)

                        newModel_ =
                            if List.length newlist == 0 then
                                { newModel | alertMessages = "Nothing To Load !" :: newModel.alertMessages }
                            else
                                { newModel | alertMessages = [] }
                    in
                        ( newModel_, cmds )
                            |> Update.Extra.andThen update (StartMainGameNewPlayerName playerName)
                            |> Update.Extra.andThen update (ProcessLoadHistory newlist savedSettings)

                ProcessLoadHistory ltups savedSettings ->
                    let
                        ( newModel, cmds ) =
                            case ltups of
                                [] ->
                                    ( model, Cmd.none )

                                head :: rest ->
                                    ( model, Cmd.none )
                                        |> Update.Extra.andThen update (InteractStepTwo (Tuple.first head) (Tuple.second head))
                                        |> Update.Extra.andThen update (ProcessLoadHistory rest savedSettings)
                    in
                        ( { newModel | settingsModel = savedSettings }, cmds )

                ExitToFinalScreen ->
                    ( { model | displayEndScreen = True }, Cmd.none )

                Loaded ->
                    ( { model | loaded = True }
                    , Cmd.none
                    )


port saveHistoryToStorage : { playerName : String, lInteractions : List SaveHistoryRecord } -> Cmd msg


port sendRequestForStoredHistory : String -> Cmd msg


port getHistoryFromStorage : ({ playerName : String, lInteractions : List SaveHistoryRecord } -> msg) -> Sub msg


subscriptions : a -> Sub Msg
subscriptions a =
    (getHistoryFromStorage LoadHistory)


convertToListIdExtraInfo : List SaveHistoryRecord -> List ( String, InteractionExtraInfo )
convertToListIdExtraInfo lobjs =
    List.map
        (\x ->
            ( x.interactableId
            , EngineTypes.InteractionExtraInfo
                (helperEmptyStringToNothing x.inputText)
                (helperEmptyStringToNothing x.inputTextForBackend)
                x.geolocationInfoText
                x.currentLocation
                EngineTypes.CommunicationFailure
                (helperEmptyStringToNothing x.mbMatchedRuleId)
            )
        )
        lobjs


helperEmptyStringToNothing : String -> Maybe String
helperEmptyStringToNothing theStr =
    if theStr == "" then
        Nothing
    else
        (Just theStr)


saveHistoryToStorageHelper : Model -> ( Model, Cmd ClientTypes.Msg )
saveHistoryToStorageHelper model =
    let
        storyHistory =
            Engine.getHistory model.engineModel

        lToSave =
            List.map
                (\x ->
                    { interactableId = Tuple.first x
                    , inputText = Tuple.second x |> .mbInputText |> Maybe.withDefault ""
                    , inputTextForBackend = Tuple.second x |> .mbInputTextForBackend |> Maybe.withDefault ""
                    , geolocationInfoText = Tuple.second x |> .geolocationInfoText
                    , currentLocation = Engine.getCurrentLocation model.engineModel
                    , mbMatchedRuleId = Tuple.second x |> .mbMatchedRuleId |> Maybe.withDefault ""
                    }
                )
                storyHistory

        infoToSave =
            { playerName = getInLanguage model.settingsModel.displayLanguage model.playerName, lInteractions = lToSave }
    in
        ( model, saveHistoryToStorage infoToSave )


getExtraInfoFromModel : Model -> String -> InteractionExtraInfo
getExtraInfoFromModel model interactableId =
    let
        currLocationStrId =
            Engine.getCurrentLocation model.engineModel

        currLocNameAndCoords =
            currLocationStrId |> findEntity model |> getDictLgNamesAndCoords Narrative.desiredLanguages
    in
        InteractionExtraInfo
            model.mbSentText
            model.mbSentText
            (GpsUtils.getCurrentGeoReportAsText currLocNameAndCoords model.geoLocation model.geoDistances 3)
            currLocationStrId
            (Dict.get interactableId model.bkendAnswerStatusDict |> Maybe.withDefault EngineTypes.NoInfoYet)
            Nothing


updateInterExtraInfoWithGeoInfo : EngineTypes.InteractionExtraInfo -> Model -> InteractionExtraInfo
updateInterExtraInfoWithGeoInfo extraInforecord model =
    let
        currLocNameAndCoords =
            Engine.getCurrentLocation model.engineModel |> findEntity model |> getDictLgNamesAndCoords Narrative.desiredLanguages
    in
        { extraInforecord
            | geolocationInfoText =
                (GpsUtils.getCurrentGeoReportAsText currLocNameAndCoords model.geoLocation model.geoDistances 3)
        }


getNewCoords : String -> Maybe GpsZone -> Bool -> EngineTypes.InteractionExtraInfo -> Cmd ClientTypes.Msg
getNewCoords interactableId mbGpsZone bval interactionExtraInfo =
    Task.attempt (NewCoordsForInterId interactableId mbGpsZone bval interactionExtraInfo) Geolocation.now


type alias LgTxt =
    { lgId : String
    , text : String
    }


textInLanguagesDecoder : Json.Decode.Decoder LgTxt
textInLanguagesDecoder =
    Json.Decode.map2 LgTxt
        (Json.Decode.field "lgId" (Json.Decode.string))
        (Json.Decode.field "text" (Json.Decode.string))


backendAnswerDecoder : String -> String -> Json.Decode.Decoder EngineTypes.AnswerInfo
backendAnswerDecoder interactableId playerAnswer =
    Json.Decode.Pipeline.decode AnswerInfo
        |> Json.Decode.Pipeline.required "maxTriesReached" (Json.Decode.bool)
        |> Json.Decode.Pipeline.hardcoded interactableId
        |> Json.Decode.Pipeline.required "questionBody" (Json.Decode.string)
        |> Json.Decode.Pipeline.hardcoded playerAnswer
        |> Json.Decode.Pipeline.required "answered" (Json.Decode.bool)
        |> Json.Decode.Pipeline.required "correctAnswer" (Json.Decode.bool)
        |> Json.Decode.Pipeline.required "incorrectAnswer" (Json.Decode.bool)
        |> Json.Decode.Pipeline.required "lSecretTextDicts" (Json.Decode.list textInLanguagesDecoder)
        |> Json.Decode.Pipeline.required "lSuccessTextDicts" (Json.Decode.list textInLanguagesDecoder)
        |> Json.Decode.Pipeline.required "lInsuccessTextDicts" (Json.Decode.list textInLanguagesDecoder)


getBackendAnswerInfo : String -> EngineTypes.InteractionExtraInfo -> String -> Cmd ClientTypes.Msg
getBackendAnswerInfo interactableId interactionExtraInfo strUrl =
    let
        apiKey =
            InfoForBkendApiRequests.getApiKey

        request =
            Http.request
                { method = "GET"
                , headers =
                    [ Http.header "x-api-key" apiKey
                    ]
                , url = strUrl
                , body = Http.emptyBody
                , expect = Http.expectJson (backendAnswerDecoder interactableId (Maybe.withDefault "" interactionExtraInfo.mbInputTextForBackend))
                , timeout = Nothing
                , withCredentials = False
                }

        newInteractionExtraInfo =
            { interactionExtraInfo | mbInputTextForBackend = Nothing }
    in
        Http.send (AnswerChecked interactableId newInteractionExtraInfo) request


getNewModelAndInteractionExtraInfoByEngineUpdate : String -> EngineTypes.InteractionExtraInfo -> Model -> ( EngineTypes.InteractionExtraInfo, Model )
getNewModelAndInteractionExtraInfoByEngineUpdate interactableId interactionExtraInfo model =
    -- only allow interaction if this interactable isnt waiting for some backend answer confirmation
    if (Dict.get interactableId model.bkendAnswerStatusDict == Just EngineTypes.WaitingForInfoRequested) then
        -- Interactable is awaiting for some backend confirmation. No interaction possible at this time
        ( interactionExtraInfo, { model | alertMessages = "Please Wait ... \n" :: model.alertMessages } )
    else
        let
            ( newEngineModel, maybeMatchedRuleId, lInteractionIncidents, mbUrlForBkendQry ) =
                Engine.update
                    interactableId
                    interactionExtraInfo
                    model.engineModel

            newInteractionExtraInfo =
                { interactionExtraInfo | mbMatchedRuleId = maybeMatchedRuleId }

            interactionIncidents =
                if model.debugMode then
                    lInteractionIncidents
                else
                    []

            newModel =
                { model
                    | engineModel = newEngineModel
                    , bkendAnswerStatusDict = Dict.update interactableId (\x -> Just EngineTypes.NoInfoYet) model.bkendAnswerStatusDict
                    , alertMessages = interactionIncidents
                }
        in
            ( newInteractionExtraInfo, newModel )



-- VIEW


view : Model -> Html ClientTypes.Msg
view model =
    if model.displayStartScreen then
        viewStartScreen model.baseImgUrl model
    else if model.displayEndScreen then
        --h1 [] [ text "Congratulations ! You reached the End . You are a master of your neighbourhood :) " ]
        Theme.EndScreen.view model.baseImgUrl model.endScreenInfo
    else
        viewMainGame model


viewMainGame :
    Model
    -> Html ClientTypes.Msg
viewMainGame model =
    let
        currentLocation =
            Engine.getCurrentLocation model.engineModel |> findEntity model

        theStoryLine =
            Dict.get model.settingsModel.displayLanguage model.languageStoryLines
                |> Maybe.withDefault []

        mbInteactableIdAtTop =
            List.head theStoryLine |> Maybe.map .interactableId

        displayState =
            { currentLocation = currentLocation
            , itemsInCurrentLocation =
                Engine.getItemsInCurrentLocation model.engineModel
                    |> List.map (findEntity model)
            , charactersInCurrentLocation =
                Engine.getCharactersInCurrentLocation model.engineModel
                    |> List.map (findEntity model)
            , exits =
                getExits currentLocation
                    |> List.map
                        (\( direction, id ) ->
                            ( direction, findEntity model id )
                        )
            , itemsInInventory =
                Engine.getItemsInInventory model.engineModel
                    |> List.map (findEntity model)
            , answerBoxMbText = model.answerBoxModel.answerBoxText
            , mbAudioFileInfo =
                List.head theStoryLine
                    |> Maybe.map .mbAudio
                    |> Maybe.withDefault Nothing
            , audioAutoplay = model.settingsModel.audioAutoplay
            , answerOptionsDict =
                Maybe.map (\x -> Engine.getInteractableAttribute "answerOptionsList" x model.engineModel) mbInteactableIdAtTop
                    |> Maybe.map (Tconverter.mbAttributeToDictStringListStringString model.debugMode)
                    |> Maybe.withDefault Dict.empty
            , layoutWithSidebar = model.settingsModel.layoutWithSidebar
            , boolTextBoxInStoryline =
                case mbInteactableIdAtTop of
                    Nothing ->
                        False

                    Just interactableId ->
                        Engine.isWritable interactableId model.engineModel
                            && Dict.get interactableId model.bkendAnswerStatusDict
                            /= Just EngineTypes.WaitingForInfoRequested
            , mbTextBoxPlaceholderText =
                case mbInteactableIdAtTop of
                    Nothing ->
                        Nothing

                    Just interactableId ->
                        Engine.getInteractableAttribute "placeholderText" interactableId model.engineModel
                            |> Tconverter.mbAttributeToMbString model.debugMode
            , settingsModel = model.settingsModel
            , alertMessages = model.alertMessages
            , ending =
                Engine.getEndingText model.engineModel
            , storyLine =
                theStoryLine
            }
    in
        if not model.loaded then
            div [ class "Loading" ] [ text "Loading..." ]
        else
            Theme.Layout.view displayState


viewStartScreen : String -> Model -> Html ClientTypes.Msg
viewStartScreen baseImgUrl model =
    Theme.StartScreen.view baseImgUrl model.startScreenInfo model.answerBoxModel


port loaded : (Bool -> msg) -> Sub msg


type alias Flags =
    { baseImgUrl : String
    , baseSoundUrl : String
    }


main : Program Flags Model ClientTypes.Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
