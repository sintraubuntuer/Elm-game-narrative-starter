module Theme.EndScreen exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


--import Html.Events exposing (..)

import ClientTypes exposing (..)


view : String -> Html ClientTypes.Msg
view baseImgUrl =
    let
        imgUrl =
            if (baseImgUrl == "") then
                -- "img/finalImage.png"
                "img/finalImage.png"
            else
                baseImgUrl ++ "finalImage.png"

        congratsMessage1 =
            "Congratulations ! You reached the End ! ..."

        congratsMessage2 =
            "You are now a hiking trail Master  :)"
    in
        div [ class "TitlePage" ]
            [ h1 [ class "TitlePage__Title" ]
                [ text <| congratsMessage1
                , br [] []
                , text <| congratsMessage2
                ]
            , div [ class "TitlePage__Prologue markdown-body" ]
                [ p []
                    [ text
                        """...
                                """
                    ]
                , img [ src imgUrl, class "StartScreenImage" ] []
                ]
            ]
