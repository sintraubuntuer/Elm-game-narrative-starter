module Theme.StartScreen exposing (..)

import Html exposing (..)


--import Html.Keyed

import Html.Attributes exposing (..)
import Html.Events exposing (..)
import ClientTypes exposing (..)
import Theme.AnswerBox exposing (..)


view : String -> Theme.AnswerBox.Model -> Html ClientTypes.Msg
view baseImgUrl answerBoxModel =
    let
        imgUrl =
            if (baseImgUrl == "") then
                "img/introImage.png"
            else
                baseImgUrl ++ "introImage.png"
    in
        div [ class "TitlePage" ]
            [ h1 [ class "TitlePage__Title" ]
                [ text <| "A Guided Tour Through Vila Sassetti - Sintra"
                , br [] []
                ]
            , h3 [ class "TitlePage__Byline" ] [ text "Uma história interactiva por Sintra Ubuntuer " ]
            , div [ class "TitlePage__Prologue markdown-body" ]
                [ p []
                    [ text """
                               a guided tour through Vila Sassetti ( Quinta da Amizade ) - Sintra  ...
                               """
                    ]
                , img [ src imgUrl, class "StartScreenImage" ] []
                ]
            , div [ class "textCenter" ]
                [ h3 [] [ text "Please type your name to start game : " ]
                , Theme.AnswerBox.view answerBoxModel.answerBoxText "pt" False Nothing (Just "investigator") "AnswerBoxStartScreen"
                ]
            , span
                [ class "TitlePage__StartGame"
                , onClick <|
                    (answerBoxModel.answerBoxText
                        |> Maybe.map String.trim
                        |> (\mbx ->
                                if mbx == (Just "") then
                                    Nothing
                                else
                                    mbx
                           )
                        |> Maybe.withDefault ""
                        |> StartMainGameNewPlayerName
                    )
                ]
                [ text "Play " ]
            ]
