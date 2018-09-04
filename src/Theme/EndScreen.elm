module Theme.EndScreen exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


--import Html.Events exposing (..)

import ClientTypes exposing (..)


view : String -> EndScreenInfo -> Html ClientTypes.Msg
view baseImgUrl endScreenInfo =
    let
        imgUrl =
            if (baseImgUrl == "") then
                "img/" ++ endScreenInfo.mainImage
            else
                baseImgUrl ++ endScreenInfo.mainImage
    in
        div [ class "TitlePage" ]
            [ h1 [ class "TitlePage__Title" ]
                [ text <| endScreenInfo.congratsMessage1
                , br [] []
                , text <| endScreenInfo.congratsMessage2
                ]
            , div [ class "TitlePage__Prologue markdown-body" ]
                [ p []
                    [ text endScreenInfo.endScreenText
                    ]
                , img [ src imgUrl, class "StartScreenImage" ] []
                ]
            ]
