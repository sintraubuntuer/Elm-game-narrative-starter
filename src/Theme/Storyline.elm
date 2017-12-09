module Theme.Storyline exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed
import Html.Attributes exposing (..)
import TranslationHelper exposing (getInLanguage)
import Theme.AnswerBox exposing (..)
import Markdown
import ClientTypes exposing (..)
import Dict exposing (Dict)


view :
    List StorySnippet
    -> String
    -> Bool
    -> Maybe String
    -> Maybe String
    -> Dict String (List ( String, String ))
    -> Maybe String
    -> Html Msg
view storyLine lgId showTextBoxInStoryline mbplaceholdertext mbanswerboxtext answerOptionsDict ending =
    let
        storyLi i { interactableName, interactableId, isWritable, interactableCssSelector, narrative, mbAudio, mbSuggestedInteractionId, mbSuggestedInteractionName, isLastInZipper } =
            let
                numLines =
                    List.length storyLine

                key =
                    interactableName ++ (toString <| numLines - i)

                classes =
                    [ ( "Storyline__Item", True )
                    , ( "Storyline__Item--" ++ interactableCssSelector, True )
                    , ( "u-fade-in", i == 0 )
                    ]

                viewMbAnswerBox =
                    if (i == 0 && isWritable && showTextBoxInStoryline) then
                        Theme.AnswerBox.view mbanswerboxtext lgId False (Just interactableId) mbplaceholdertext "AnswerBoxInStoryLine2"
                    else
                        text ""

                viewMbAnswerButtons =
                    if (i == 0 && not (Dict.isEmpty answerOptionsDict)) then
                        answerOptionsDict
                            |> Dict.get lgId
                            |> Maybe.withDefault []
                            |> List.map (\( txtval, txtDisp ) -> button [ onClick (InteractSendingText interactableId txtval) ] [ text txtDisp ])
                            |> div [ class "OptionButton" ]
                    else
                        div [] [ text "" ]

                viewMbMoreLink =
                    if (i == 0 && (not isLastInZipper)) then
                        div [ class "textCenter" ]
                            [ br [] []
                            , a [ class "moreLink", onClick <| Interact <| interactableId ]
                                [ text <| getInLanguage lgId "___more___" ]
                            ]
                    else
                        text ""

                viewMbSuggestedInteraction =
                    if (i == 0) then
                        case mbSuggestedInteractionId of
                            Just suggestedInteractableId ->
                                div [ class "textRight" ]
                                    [ p [ class "suggestInteraction" ] [ text <| getInLanguage lgId "___SUGGESTED_INTERACTION___" ]
                                    , a [ class "suggestedInteractionLink", onClick <| Interact <| suggestedInteractableId ]
                                        [ text <| Maybe.withDefault suggestedInteractableId mbSuggestedInteractionName ]
                                    ]

                            Nothing ->
                                text ""
                    else
                        text ""

                options : Markdown.Options
                options =
                    let
                        dOptions =
                            Markdown.defaultOptions
                    in
                        { dOptions | sanitize = True }

                markdownToSanitizedHtml : List (Attribute msg) -> String -> Html msg
                markdownToSanitizedHtml lattrs userInput =
                    Markdown.toHtmlWith options lattrs userInput
            in
                ( key
                , li [ classList classes ] <|
                    [ h4 [ class "Storyline__Item__Action" ] <| [ text interactableName ]
                    , markdownToSanitizedHtml [ class "Storyline__Item__Narrative markdown-body" ] narrative
                    , viewMbAnswerBox
                    , viewMbAnswerButtons
                    , viewMbMoreLink
                    , viewMbSuggestedInteraction

                    --, viewMbAudio
                    ]
                        ++ if (i == 0 && ending /= Nothing) then
                            [ h5
                                [ class "Storyline__Item__Ending" ]
                                [ text <| Maybe.withDefault "The End" ending ]
                            ]
                           else
                            []
                )
    in
        Html.Keyed.ol [ class "Storyline" ]
            (List.indexedMap storyLi storyLine)
