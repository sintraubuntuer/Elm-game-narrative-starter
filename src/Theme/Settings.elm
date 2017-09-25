module Theme.Settings exposing (init, Model, update, view)

import Html exposing (..)


--import Html.Keyed

import Html.Attributes exposing (..)
import Html.Events exposing (..)
import ClientTypes exposing (..)


--import Components exposing (..)
--import Tuple

import Dict exposing (Dict)
import TranslationHelper exposing (getInLanguage)


type alias Model =
    ClientTypes.SettingsModel


init : Dict String String -> Model
init theLanguages =
    { availableLanguages = theLanguages
    , displayLanguage = "pt"
    , gpsOptionsEnabled = True -- this control wether gpsOptions appear on sidebar and are available to be changed by the user
    , dontNeedToBeInZone = False
    , audioOptionsEnabled = True -- this control wether audio Options appear on sidebar and are available to be changed by the user
    , audioAutoplay = False
    , layoutWithSidebar = True
    , showAnswerBoxInSideBar = False
    , showExpandedSettings = False
    , saveLoadEnabled = True -- this controls wether save/load options appear on sidebar and are available to be changed by the user
    , showSaveLoad = False
    , showExitToFinalScreenButton = False
    }


update : ClientTypes.ToSettingsMsg -> Model -> Model
update msg model =
    case msg of
        SetDontNeedToBeInZone bval ->
            { model | dontNeedToBeInZone = bval }

        SetDisplayLanguage lgId ->
            { model | displayLanguage = lgId }

        SetAvailableLanguages dlanguages ->
            { model | availableLanguages = dlanguages }

        SettingsToggleShowExpanded ->
            { model | showExpandedSettings = not model.showExpandedSettings }

        SettingsChangeOptionAutoplay bautoplay ->
            { model | audioAutoplay = bautoplay }

        SettingsToggleShowHideSaveLoadBtns ->
            { model | showSaveLoad = not model.showSaveLoad }

        SettingsLayoutWithSidebar bWithSidebar ->
            { model | layoutWithSidebar = bWithSidebar }

        SettingsShowExitToFinalScreenButton ->
            { model | showExitToFinalScreenButton = not model.showExitToFinalScreenButton }



{-
   updateAvailableLanguages : Dict String String -> Model -> Model
   updateAvailableLanguages dlanguages model  =
       { model | availableLanguages =  dlanguages }
-}


view : Model -> Html ClientTypes.Msg
view model =
    let
        settingsClassStr =
            if (model.layoutWithSidebar) then
                "Settings"
            else
                "Settings__NoSidebar"
    in
        div [ class settingsClassStr ]
            [ if (model.showExitToFinalScreenButton) then
                viewExitToFinalScreenButton model
              else
                text ""
            , h3 [ class "title" ]
                [ text <| getInLanguage model.displayLanguage "___Settings___"
                , text "  "
                , viewShowHideSettingsOptions model
                ]
            , if (model.showExpandedSettings) then
                div []
                    [ viewLanguageGpsAudioAndLayoutOptions model
                    , br [] []
                    , if model.saveLoadEnabled then
                        viewSaveLoadButtons model
                      else
                        text ""
                    ]
              else
                text ""
            ]


viewExitToFinalScreenButton : Model -> Html ClientTypes.Msg
viewExitToFinalScreenButton model =
    div []
        [ h3 [ class "title" ] [ text <| getInLanguage model.displayLanguage "___EXIT___" ]
        , button [ class "showHideBtn", onClick ExitToFinalScreen ] [ text "Exit" ]
        ]


viewShowHideSettingsOptions : Model -> Html ClientTypes.Msg
viewShowHideSettingsOptions model =
    let
        theText =
            if (model.showExpandedSettings) then
                "(Hide)"
            else
                "(Show)"
    in
        a [ class "u-selectable", onClick ToggleShowExpandedSettings ]
            --[ class "form-group" ]
            [ text theText
            ]


viewLanguageGpsAudioAndLayoutOptions : Model -> Html ClientTypes.Msg
viewLanguageGpsAudioAndLayoutOptions model =
    div []
        [ optionLanguagesView model.availableLanguages model.displayLanguage
        , if model.gpsOptionsEnabled then
            optionGpsCheckZone model.dontNeedToBeInZone model.displayLanguage
          else
            text ""
        , if model.audioOptionsEnabled then
            optionAudioAutoplay model.audioAutoplay model.displayLanguage
          else
            text ""
        , optionLayout model.layoutWithSidebar model.displayLanguage
        ]


viewSaveLoadButtons : Model -> Html ClientTypes.Msg
viewSaveLoadButtons model =
    div []
        [ if (model.layoutWithSidebar) then
            h3 [] [ text <| getInLanguage model.displayLanguage "___SAVE_LOAD___" ]
          else
            label [ class "col-form-label" ] [ text <| getInLanguage model.displayLanguage "___SAVE_LOAD___" ]
        , viewShowHideSaveLoad model
        , if (model.showSaveLoad) then
            div []
                [ div [ class "" ]
                    [ button [ class "saveBtn", onClick SaveHistory ] [ text "Save" ]
                    ]

                --, br [] []
                , div [ class "" ]
                    [ button [ class "loadBtn", onClick RequestForStoredHistory ] [ text "Load" ]
                    ]
                , br [] []
                ]
          else
            text ""
        ]


radio : a -> a -> String -> ClientTypes.Msg -> List (Html Msg)
radio frommodel opt name msg =
    [ input
        [ -- class "form-check-input"
          type_ "radio"
        , checked (frommodel == opt)
        , onCheck (\_ -> msg)
        ]
        []
    , text name
    ]


optionLanguagesView : Dict String String -> String -> Html ClientTypes.Msg
optionLanguagesView availableLanguages displayLanguageId =
    div [ class "form-group" ]
        --row" ]
        [ label
            [ class "col-form-label" --"col-form-label col-sm-3"
            ]
            [ text <| getInLanguage displayLanguageId "___Language___" ]
        , div
            [ class "" --"form-field" --"col-sm-9"
            ]
          <|
            (Dict.map (\lgId lg -> div [ class "theradios" ] (radio displayLanguageId lgId lg (ChangeOptionDisplayLanguage lgId))) availableLanguages
                |> Dict.values
            )
        ]


optionGpsCheckZone : Bool -> String -> Html ClientTypes.Msg
optionGpsCheckZone bdontcheck displayLanguageId =
    div [ class "form-group" ]
        [ label [ class "col-form-label" ] [ text <| getInLanguage displayLanguageId "___Check_gps_coords___" ]
        , div [] <|
            [ div [ class "theradios" ] (radio bdontcheck True "dont check gps" (ChangeOptionDontCheckGps True))
            , div [ class "theradios" ] (radio (bdontcheck) False "check" (ChangeOptionDontCheckGps False))
            ]
        ]


optionAudioAutoplay : Bool -> String -> Html ClientTypes.Msg
optionAudioAutoplay bautoplay displayLanguageId =
    div [ class "form-group" ]
        [ label [ class "col-form-label" ] [ text <| getInLanguage displayLanguageId "___AUDIO___" ]
        , div [] <|
            [ div [ class "theradios" ] (radio bautoplay True "autoplay" (ChangeOptionAudioAutoplay True))
            , div [ class "theradios" ] (radio (bautoplay) False "dont autoplay" (ChangeOptionAudioAutoplay False))
            ]
        ]


optionLayout : Bool -> String -> Html ClientTypes.Msg
optionLayout bWithSidebar displayLanguageId =
    div [ class "form-group" ]
        [ label [ class "col-form-label" ] [ text <| getInLanguage displayLanguageId "___LAYOUT_OPTIONS___" ]
        , div [] <|
            [ div [ class "theradios" ] (radio bWithSidebar True "with Sidebar" (LayoutWithSideBar True))
            , div [ class "theradios" ] (radio (bWithSidebar) False "no Sidebar" (LayoutWithSideBar False))
            ]
        ]


viewShowHideSaveLoad : Model -> Html ClientTypes.Msg
viewShowHideSaveLoad model =
    let
        theText =
            if (model.showSaveLoad) then
                "Hide"
            else
                "Show"
    in
        div []
            [ button [ class "showHideBtn", onClick ToggleShowHideSaveLoadBtns ] [ text theText ]
            ]
