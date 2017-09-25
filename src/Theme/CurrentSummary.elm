module Theme.CurrentSummary exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import ClientTypes exposing (..)
import Components exposing (..)
import TranslationHelper exposing (getInLanguage)


view :
    Entity
    -> List Entity
    -> List Entity
    -> List String
    -> String
    -> Html Msg
view currentLocation props characters lAlertMessages lgId =
    let
        isEmpty =
            List.isEmpty characters && List.isEmpty props

        interactableView msg entity =
            span
                [ class "CurrentSummary__StoryElement u-selectable"
                , onClick <| msg <| Tuple.first entity
                ]
                [ text <| .name <| getSingleLgDisplayInfo lgId entity ]

        format list =
            let
                interactables =
                    if List.length list > 2 then
                        (List.take (List.length list - 1) list
                            |> List.intersperse (text ", ")
                        )
                            ++ (text <| getInLanguage lgId "__and__")
                            :: (List.drop (List.length list - 1) list)
                    else
                        List.intersperse (text <| getInLanguage lgId "__and__") list
            in
                interactables ++ [ text "." ]

        charactersList =
            if not <| List.isEmpty characters then
                characters
                    |> List.map (interactableView Interact)
                    |> format
                    |> (::) (text <| getInLanguage lgId "__Characters_here__")
                    |> p []
            else
                span [] []

        propsList =
            if not <| List.isEmpty props then
                props
                    |> List.map (interactableView Interact)
                    |> format
                    |> (::) (text <| getInLanguage lgId "__Items_here__")
                    |> p []
            else
                span [] []
    in
        div [ class "CurrentSummary", style [] ] <|
            [ h1 [ class "Current-location" ]
                [ getSingleLgDisplayInfo lgId currentLocation |> .name |> text
                ]
            ]
                ++ if isEmpty then
                    [ text <| getInLanguage lgId "__Nothing_here__" ]
                   else
                    [ charactersList, propsList ]
