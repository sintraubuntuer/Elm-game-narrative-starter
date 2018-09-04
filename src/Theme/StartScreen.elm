module Theme.StartScreen exposing (..)

import Html exposing (..)


--import Html.Keyed

import Html.Attributes exposing (..)
import Html.Events exposing (..)
import ClientTypes exposing (..)
import Theme.AnswerBox exposing (..)


view : String -> StartScreenInfo -> Theme.AnswerBox.Model -> Html ClientTypes.Msg
view baseImgUrl startScreenInfo answerBoxModel =
    let
        imgUrl =
            if (baseImgUrl == "") then
                "img/" ++ startScreenInfo.mainImage
            else
                baseImgUrl ++ startScreenInfo.mainImage
    in
        div [ class "TitlePage" ]
            [ h1 [ class "TitlePage__Title" ]
                [ text <| startScreenInfo.title_line1
                , br [] []
                , text startScreenInfo.title_line2
                ]
            , h3 [ class "TitlePage__Byline" ] [ text startScreenInfo.byLine ]
            , div [ class "TitlePage__Prologue markdown-body" ]
                [ p []
                    [ text startScreenInfo.smallIntro
                    ]
                , img [ src imgUrl, class "StartScreenImage" ] []
                ]
            , div [ class "textCenter" ]
                [ h3 [] [ text "Please type your name to start game : " ]
                , Theme.AnswerBox.view answerBoxModel.answerBoxText "pt" False Nothing (Just startScreenInfo.tboxNamePlaceholder) "AnswerBoxStartScreen"
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
