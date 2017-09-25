module Theme.AnswerBox exposing (..)

import Html exposing (..)


--import Html.Keyed

import Html.Attributes exposing (..)
import Html.Events exposing (..)
import ClientTypes exposing (..)
import TranslationHelper exposing (getInLanguage)


--import Components exposing (..)
--import Tuple


type alias Model =
    { answerBoxText : Maybe String
    }


init : Model
init =
    { answerBoxText = Nothing
    }


update : String -> Model -> Model
update theText model =
    if theText == "" then
        { model | answerBoxText = Nothing }
    else
        { model | answerBoxText = Just theText }


view : Maybe String -> String -> Bool -> Maybe String -> Maybe String -> String -> Html Msg
view answerboxtext lgId showHeaders mbInteractableId mbPlaceHolderText className =
    let
        placeHolderText =
            case mbPlaceHolderText of
                Nothing ->
                    "___type_answer___"

                Just txt ->
                    txt
    in
        div [ class className ]
            [ if showHeaders then
                h3 [] [ text "Text Box" ]
              else
                text ""
            , input
                [ type_ "text"
                , placeholder (getInLanguage lgId placeHolderText)
                , autofocus True
                , value (Maybe.withDefault "" answerboxtext)
                , onInput NewUserSubmitedText
                ]
                []
            , case mbInteractableId of
                Just theId ->
                    button [ onClick (InteractSendingText theId (Maybe.withDefault "" answerboxtext)) ] [ text "OK" ]

                Nothing ->
                    text ""
            ]
