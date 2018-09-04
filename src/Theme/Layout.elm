module Theme.Layout exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Theme.CurrentSummary exposing (..)
import Theme.Storyline exposing (..)
import Theme.Locations exposing (..)
import Theme.Inventory exposing (..)
import Theme.Settings exposing (..)
import Theme.AlertMessages exposing (..)
import ClientTypes exposing (..)
import Components exposing (..)
import Dict exposing (Dict)


type alias DisplayState =
    { currentLocation : Entity
    , itemsInCurrentLocation : List Entity
    , charactersInCurrentLocation : List Entity
    , exits : List ( Direction, Entity )
    , itemsInInventory : List Entity
    , answerBoxMbText : Maybe String
    , mbAudioFileInfo : Maybe ClientTypes.AudioFileInfo
    , audioAutoplay : Bool
    , answerOptionsDict : Dict String (List ( String, String ))
    , layoutWithSidebar : Bool
    , boolTextBoxInStoryline : Bool
    , mbTextBoxPlaceholderText : Maybe String
    , settingsModel : Theme.Settings.Model
    , alertMessages : List String
    , ending : Maybe String
    , storyLine : List StorySnippet
    }


view : DisplayState -> Html Msg
view displayState =
    let
        ( layoutClass, layoutMainClass ) =
            if (displayState.layoutWithSidebar) then
                ( "Layout", "Layout__Main" )
            else
                ( "Layout__NoSidebar", "Layout__Main__NoSidebar" )
    in
        div [ class <| "GamePage GamePage--" ++ Components.getClassName displayState.currentLocation ]
            [ div
                -- this is useful if you want to add a full-screen background image via the ClassName component
                [ class <| "GamePage__background GamePage__background--" ++ Components.getClassName displayState.currentLocation ]
                []
            , div [ class layoutClass ]
                [ div [ class layoutMainClass ] <|
                    [ if (not displayState.settingsModel.layoutWithSidebar) then
                        div [ class "" ]
                            [ Theme.Settings.view displayState.settingsModel
                            ]
                      else
                        text ""
                    , Theme.CurrentSummary.view
                        displayState.currentLocation
                        displayState.itemsInCurrentLocation
                        displayState.charactersInCurrentLocation
                        displayState.alertMessages
                        displayState.settingsModel.displayLanguage
                    , if (not displayState.layoutWithSidebar) then
                        viewExtraInfo displayState "Layout__NoSidebar__ExtraInfo"
                      else
                        text ""
                    , viewMbAudioFile displayState.mbAudioFileInfo displayState.audioAutoplay
                    , Theme.AlertMessages.viewAlertMessages displayState.alertMessages displayState.settingsModel.displayLanguage
                    , Theme.Storyline.view
                        displayState.storyLine
                        displayState.settingsModel.displayLanguage
                        displayState.boolTextBoxInStoryline
                        displayState.mbTextBoxPlaceholderText
                        displayState.answerBoxMbText
                        displayState.answerOptionsDict
                        displayState.ending
                    ]
                , if (displayState.layoutWithSidebar) then
                    viewExtraInfo displayState "Layout__Sidebar"
                  else
                    text ""
                ]
            ]


viewExtraInfo : DisplayState -> String -> Html Msg
viewExtraInfo displayState layoutClassStr =
    div [ class layoutClassStr ]
        [ Theme.Locations.view
            displayState.exits
            displayState.currentLocation
            displayState.settingsModel.displayLanguage
            displayState.settingsModel.layoutWithSidebar
        , Theme.Inventory.view
            displayState.itemsInInventory
            displayState.settingsModel.displayLanguage
            displayState.settingsModel.layoutWithSidebar
        , if (displayState.settingsModel.layoutWithSidebar) then
            Theme.Settings.view displayState.settingsModel
          else
            text ""
        ]


viewMbAudioFile : Maybe ClientTypes.AudioFileInfo -> Bool -> Html ClientTypes.Msg
viewMbAudioFile mbAudioFileInfo audioAutoplay =
    let
        audioHtml =
            mbAudioFileInfo
                |> Maybe.map
                    (\fileinfo ->
                        div []
                            [ audio
                                [ src fileinfo.fileName --entry.audioUrl
                                , controls True
                                , autoplay audioAutoplay
                                ]
                                []
                            ]
                    )
                |> Maybe.withDefault (h3 [] [ text "" ])

        out =
            div []
                [ span []
                    [ if mbAudioFileInfo /= Nothing then
                        (text "Audio : ")
                      else
                        (text "")
                    ]
                , audioHtml
                ]
    in
        out
