module OurStory2.Rules exposing (..)

import Engine exposing (..)
import Components exposing (..)
import Dict exposing (Dict)
import OurStory2.Narrative as Narrative


--import InfoForBkendApiRequests exposing (backendAnswerCheckerUrl)
--import Audio

import ClientTypes exposing (AudioFileInfo)


numberOfDesiredStages : Int
numberOfDesiredStages =
    10


questionsOnEveryStageExcept : List Int
questionsOnEveryStageExcept =
    [ 6 ]


correctAnswerNotRequiredToMove : List Int
correctAnswerNotRequiredToMove =
    [ 7 ]


{-| This specifies the initial story world model. At a minimum, you need to set a starting location with the `moveTo` command. You may also want to place various items and characters in different locations. You can also specify a starting scene if required.
-}
startingState : List Engine.ChangeWorldCommand
startingState =
    [ moveTo "onceUponAtime"
    , moveCharacterToLocation "playerOne" "onceUponAtime"
    , moveItemToLocation "gps" "stage1"
    , moveItemToLocationFixed "creditsInfo" (getLastStageId)
    ]
        ++ moveQuestionsToStagesFixed
        ++ makeQuestionsAmultiChoice [ 2, 3, 4, 7 ]
        -- since we made some of the questions multi-choice no need to also present a textbox ( although we can if we want )
        ++ makeQuestionsWritableExcept [ 2, 3, 4, 7 ]


getQuestionId : Int -> String
getQuestionId nr =
    "question" ++ toString nr


getStageId : Int -> String
getStageId nr =
    "stage" ++ toString nr


getLastStageId : String
getLastStageId =
    "stage" ++ (toString numberOfDesiredStages)


getLastStageNr : Int
getLastStageNr =
    numberOfDesiredStages


getPenultimateStageId : String
getPenultimateStageId =
    "stage" ++ (toString (numberOfDesiredStages - 1))


getPenultimateStageNr : Int
getPenultimateStageNr =
    (numberOfDesiredStages - 1)


makeQuestionsAmultiChoice : List Int -> List Engine.ChangeWorldCommand
makeQuestionsAmultiChoice lquestionNrs =
    let
        createForOneElem questionNr =
            --createAttributeIfNotExists ( aDictStringLSS <| Narrative.getQuestionAvailableChoicesDict questionNr  )  "answerOptionsList"  ("question" ++ toString questionNr)
            createAmultiChoice (Narrative.getQuestionAvailableChoicesDict questionNr) (getQuestionId questionNr)
    in
        List.map createForOneElem lquestionNrs


getListOfStageQuestions : List String
getListOfStageQuestions =
    List.range 1 numberOfDesiredStages
        |> List.filter (\x -> not (List.member x questionsOnEveryStageExcept))
        |> List.map getQuestionId


getListOfStageQuestionNrs : List Int
getListOfStageQuestionNrs =
    List.range 1 numberOfDesiredStages
        |> List.filter (\x -> not (List.member x questionsOnEveryStageExcept))


getListOfStageIdWithQuestions : List String
getListOfStageIdWithQuestions =
    List.range 1 numberOfDesiredStages
        |> List.filter (\x -> not (List.member x questionsOnEveryStageExcept))
        |> List.map getStageId


getListOfStageNrsWithQuestions : List Int
getListOfStageNrsWithQuestions =
    List.range 1 numberOfDesiredStages
        |> List.filter (\x -> not (List.member x questionsOnEveryStageExcept))


moveQuestionsToStagesFixed : List Engine.ChangeWorldCommand
moveQuestionsToStagesFixed =
    let
        moveItFixed nr =
            moveItemToLocationFixed (getQuestionId nr) (getStageId nr)
    in
        List.range 1 numberOfDesiredStages
            |> List.filter (\x -> not (List.member x questionsOnEveryStageExcept))
            |> List.map moveItFixed


makeQuestionsWritableExcept : List Int -> List Engine.ChangeWorldCommand
makeQuestionsWritableExcept lnotWritable =
    let
        makeItWritable n =
            makeItemWritable (getQuestionId n)
    in
        List.range 1 numberOfDesiredStages
            |> List.filter (\x -> not (List.member x questionsOnEveryStageExcept))
            |> List.filter (\x -> not (List.member x lnotWritable))
            |> List.map makeItWritable


makeAllQuestionsWritable : List Engine.ChangeWorldCommand
makeAllQuestionsWritable =
    makeQuestionsWritableExcept []


{-| A simple helper for making rules, since I want all of my rules to include RuleData and Narrative components.
-}
rule : String -> Engine.Rule_ -> Dict String (List String) -> Entity
rule id ruleData narratives =
    entity id
        |> addRuleData (completeTheRule ruleData)
        |> addLanguageNarratives narratives


ruleWithQuasiChange : String -> Engine.Rule -> Dict String (List String) -> Entity
ruleWithQuasiChange id ruleData narratives =
    entity id
        |> addRuleData ruleData
        |> addLanguageNarratives narratives


ruleWithAudioContent : String -> Engine.Rule_ -> Dict String (List String) -> Dict String ClientTypes.AudioFileInfo -> Entity
ruleWithAudioContent id ruleData narratives audiodict =
    rule id ruleData narratives
        |> addAllLanguagesAudio audiodict


{-| The first parameter to `rule` is an id for that rule. It must be unique, but generally isn't used directly anywhere else (though it gets returned from `Engine.update`, so you could do some special behavior if a specific rule matches). I like to write a short summary of what the rule is for as the id to help me easily identify them.
Note that the ids used in the rules must match the ids set in `Manifest.elm`.
-}
standardRuleTryMoveToNplusOneAndFail : ( Int, Int ) -> Entity
standardRuleTryMoveToNplusOneAndFail ( stageNr, questionNr ) =
    rule ("interacting with higher Stage " ++ toString (stageNr + 1) ++ "  and failing because wrong answer")
        { interaction = with (getStageId (stageNr + 1))
        , conditions =
            [ currentLocationIs (getStageId stageNr)
            , characterIsInLocation "playerOne" (getStageId stageNr)
            , itemIsNotCorrectlyAnswered (getQuestionId questionNr)
            ]
        , changes =
            []
        }
        (Narrative.interactingWithStageNDict (stageNr + 1) "withoutPreviousAnswered")


{-| type of rule we should use when we want the player to be able to move to stage N+1 only after
answering correctly to a question at stage N
-}
standardRuleMoveToNplusOneRestricted : ( Int, Int ) -> Entity
standardRuleMoveToNplusOneRestricted ( stageNr, questionNr ) =
    rule ("interacting with Stage " ++ toString (stageNr + 1) ++ " from lower correct answer required")
        { interaction = with (getStageId (stageNr + 1))
        , conditions =
            [ currentLocationIs (getStageId stageNr)
            , characterIsInLocation "playerOne" (getStageId stageNr)
            , itemIsCorrectlyAnswered (getQuestionId questionNr)
            ]
        , changes =
            [ moveTo (getStageId (stageNr + 1))
            , moveCharacterToLocation "playerOne" (getStageId (stageNr + 1))
            ]
        }
        (Narrative.interactingWithStageNDict (stageNr + 1) "defaultStageDescription")


{-| Same as above , but in this case no answer or correct answer to a question is required
-}
standardRuleMoveToNplusOneNotRestricted : Int -> Entity
standardRuleMoveToNplusOneNotRestricted stageNr =
    let
        currLocationId =
            if stageNr == 0 then
                "onceUponAtime"
            else
                getStageId stageNr
    in
        rule ("interacting with Stage " ++ toString (stageNr + 1) ++ " from lower")
            { interaction = with (getStageId (stageNr + 1))
            , conditions =
                [ currentLocationIs currLocationId
                , characterIsInLocation "playerOne" currLocationId
                ]
            , changes =
                [ moveTo (getStageId (stageNr + 1))
                , moveCharacterToLocation "playerOne" (getStageId (stageNr + 1))
                ]
            }
            (Narrative.interactingWithStageNDict (stageNr + 1) "defaultStageDescription")


standardInteractionWithQuestionNr : Int -> Entity
standardInteractionWithQuestionNr questionNr =
    let
        correctAnswers =
            (Narrative.getQuestionAnswers questionNr)

        stageNr =
            questionNr
    in
        ruleWithQuasiChange ("view question" ++ toString questionNr)
            { interaction = with (getQuestionId questionNr)
            , conditions =
                []
            , changes = []
            , quasiChanges =
                [ check_IfAnswerCorrect
                    correctAnswers
                    (checkAnswerData
                        -- max number of tries to answer the Question
                        (Narrative.getQuestionsMaxNrTries questionNr)
                        -- whether the answer checker should be case sensitive or case insensitive
                        caseInsensitiveAnswer
                        -- whether the answer checker should  pay attention to whitespaces
                        answerSpacesDontMatter
                        -- type of feedback to show about answer ( correct , incorrect , etc )
                        headerAnswerAndCorrectIncorrect
                        -- Additional text dict ( in several languages) to show if question is correctly answered)
                        (Narrative.additionalTextIfAnswerCorrectDict questionNr)
                        -- Additional text dict ( in several languages) to add if question is incorrectly answered
                        (Narrative.additionalTextIfAnswerIncorrectDict questionNr)
                        -- List of attributes we want to create in the question ( Item ) if question is correctly answered
                        []
                        [ ( getStageId stageNr, "additionalTextDict", aDictStringString Narrative.additionalStageInfoAfterQuestionAnsweredDict ) ]
                    )
                    (getQuestionId questionNr)
                ]
            , quasiChangeWithBkend = noQuasiChangeWithBackend
            }
            (Narrative.interactingWithQuestionNDict questionNr)


interactionWithQuestionNrAllQuestionsAnsweredButThisOne : Int -> Entity
interactionWithQuestionNrAllQuestionsAnsweredButThisOne questionNr =
    let
        correctAnswers =
            (Narrative.getQuestionAnswers questionNr)

        stageNr =
            questionNr

        lsuggestedInteractionIfLastStage =
            if stageNr == getLastStageNr then
                [ ( "suggestedInteraction", astring "finalPaper" ) ]
            else
                []

        additionalTextForStages =
            List.range 1 (numberOfDesiredStages - 1)
                |> List.map getStageId
                |> List.map (\x -> ( x, "additionalTextDict", aDictStringString Narrative.additionalStageInfoAfterAllQuestionsAnsweredDict ))
    in
        ruleWithQuasiChange ("view question" ++ toString questionNr ++ " all questions answered but this one ")
            { interaction = with (getQuestionId questionNr)
            , conditions =
                getListOfStageQuestions
                    |> List.filter (\x -> x /= getQuestionId questionNr)
                    |> List.map itemIsCorrectlyAnswered
                    |> List.append [ itemIsOffScreen "finalPaper" ]
            , changes =
                []
            , quasiChanges =
                [ check_IfAnswerCorrect
                    correctAnswers
                    (checkAnswerData
                        (Narrative.getQuestionsMaxNrTries questionNr)
                        caseInsensitiveAnswer
                        answerSpacesDontMatter
                        headerAnswerAndCorrectIncorrect
                        (Narrative.additionalTextIfAnswerCorrectDict questionNr)
                        (Narrative.additionalTextIfAnswerIncorrectDict questionNr)
                        ([ ( "warningMessage", aDictStringString Narrative.goodNewsMessageAfterAllQuestionsAnsweredDict ) ] ++ lsuggestedInteractionIfLastStage)
                        additionalTextForStages
                    )
                    ("question" ++ toString questionNr)
                ]
            , quasiChangeWithBkend = noQuasiChangeWithBackend
            }
            (Narrative.interactingWithQuestionNDict questionNr)


standardRuleMoveToNminusOne : ( Int, Int ) -> Entity
standardRuleMoveToNminusOne ( stageNr, questionNr ) =
    let
        ntype =
            "enteringFromHigherStage"
    in
        rule ("interacting with Stage " ++ toString (stageNr - 1) ++ " from higher")
            { interaction = with (getStageId (stageNr - 1))
            , conditions =
                [ currentLocationIs (getStageId (stageNr))
                ]
            , changes =
                [ moveTo (getStageId (stageNr - 1))
                , moveCharacterToLocation "playerOne" (getStageId (stageNr - 1))
                ]
            }
            (Narrative.interactingWithStageNDict (stageNr - 1) ntype)


lRulesInteractingWithGps : List Entity
lRulesInteractingWithGps =
    [ rule "taking gps"
        { interaction = with "gps"
        , conditions =
            [ characterIsInLocation "playerOne" "stage1"
            , itemIsInLocation "gps" "stage1"
            ]
        , changes =
            [ moveItemToInventory "gps" ]
        }
        Narrative.takeGpsDict
    , ruleWithQuasiChange "looking at gps"
        { interaction = with "gps"
        , conditions =
            []
        , changes =
            []
        , quasiChanges =
            [ write_GpsInfoToItem "gps" ]
        , quasiChangeWithBkend = noQuasiChangeWithBackend
        }
        Narrative.lookAtGpsDict
    ]


lRulesInteractingWithCreditsInfo : List Entity
lRulesInteractingWithCreditsInfo =
    [ rule "view creditsInfo"
        { interaction = with "creditsInfo"
        , conditions =
            [-- characterIsInLocation "playerOne" ( getLastStageId )
             -- , itemIsInLocation "creditsInfo"  ( getLastStageId )
            ]
        , changes =
            []
        }
        Narrative.theCreditsInformationDict
    ]


getListOfConditionsAllQuestionsAnswered : List Engine.Condition
getListOfConditionsAllQuestionsAnswered =
    getListOfStageQuestions
        |> List.map itemIsCorrectlyAnswered


lRulesMakeFinalPaperAppearAfterAllQuestionsAnswered : List Entity
lRulesMakeFinalPaperAppearAfterAllQuestionsAnswered =
    [ rule "final paper appears player moving from penultimate stage to last stage"
        { interaction = with getLastStageId
        , conditions =
            getListOfStageQuestions
                |> List.map itemIsCorrectlyAnswered
                |> List.append [ itemIsOffScreen "finalPaper" ]
                |> List.append [ currentLocationIs getPenultimateStageId ]
                |> List.append [ characterIsInLocation "playerOne" getPenultimateStageId ]
        , changes =
            [ moveTo getLastStageId
            , moveCharacterToLocation "playerOne" getLastStageId
            , moveItemToLocation "finalPaper" getLastStageId
            ]
        }
        (Narrative.interactingWithStageNDict getLastStageNr "defaultStageDescription")
    ]


lRuleInteractingWithFinalPaper : List Entity
lRuleInteractingWithFinalPaper =
    [ rule "interaction With Final Paper"
        { interaction = with "finalPaper"
        , conditions =
            getListOfStageQuestions
                |> List.map itemIsCorrectlyAnswered
        , changes =
            [ setAttributeValue (abool True) "gameHasEnded" "gameStateItem"
            , moveItemToInventory "finalPaper"
            ]
        }
        Narrative.interactingWithFinalPaperDict
    ]


lRuleGameHasEnded : List Entity
lRuleGameHasEnded =
    [ rule "game has ended"
        { interaction =
            withAnyLocationAnyCharacterAfterGameEnded

        --withAnythingAfterGameEnded
        , conditions =
            [ attrValueIsEqualTo (abool True) "gameHasEnded" "gameStateItem"
            ]
        , changes =
            [ endStory "notFreezingEnd" "The End"
            ]
        }
        Narrative.gameHasEndedDict
    ]


{-| All of the rules that govern your story.
Order does not matter, but I like to organize the rules by the story objects they are triggered by. This makes it easier to ensure I have set up the correct criteria so the right rule will match at the right time.
Note that the ids used in the rules must match the ids set in `Manifest.elm`.
-}
rules : Dict String Components
rules =
    let
        listOfStageNrs =
            List.range 1 numberOfDesiredStages

        lRulesToTryMoveToNextStageAndFail =
            List.take ((List.length listOfStageNrs) - 1) listOfStageNrs
                |> List.filter (\x -> not (List.member x questionsOnEveryStageExcept))
                |> List.filter (\x -> not (List.member x correctAnswerNotRequiredToMove))
                |> List.map (\x -> ( x, x ))
                |> List.map standardRuleTryMoveToNplusOneAndFail

        lRulesToMoveToNextStageRestricted =
            List.take ((List.length listOfStageNrs) - 1) listOfStageNrs
                |> List.filter (\x -> not (List.member x questionsOnEveryStageExcept))
                |> List.filter (\x -> not (List.member x correctAnswerNotRequiredToMove))
                |> List.map (\x -> ( x, x ))
                |> List.map standardRuleMoveToNplusOneRestricted

        lRulesToMoveToNextStageNotRestricted =
            List.take ((List.length listOfStageNrs) - 1) listOfStageNrs
                |> List.filter
                    (\x ->
                        (List.member x questionsOnEveryStageExcept
                            || List.member x correctAnswerNotRequiredToMove
                        )
                    )
                -- theres's no restriction when moving from stage0 ("onceuponatime") to stage1
                |> List.append [ 0 ]
                |> List.map standardRuleMoveToNplusOneNotRestricted

        lRulesToMoveToPreviousStage =
            List.tail listOfStageNrs
                |> Maybe.withDefault []
                |> List.map (\x -> ( x, x ))
                |> List.map standardRuleMoveToNminusOne

        lRulesAboutQuestions =
            List.range 1 numberOfDesiredStages
                |> List.filter (\x -> not (List.member x questionsOnEveryStageExcept))
                |> List.map standardInteractionWithQuestionNr

        lRulesAboutQuestionsAllQuestionsAnsweredButOne =
            List.range 1 numberOfDesiredStages
                |> List.filter (\x -> not (List.member x questionsOnEveryStageExcept))
                |> List.map interactionWithQuestionNrAllQuestionsAnsweredButThisOne

        lRules =
            List.append lRulesToMoveToNextStageRestricted lRulesToMoveToPreviousStage
                |> List.append lRulesToTryMoveToNextStageAndFail
                |> List.append lRulesToMoveToNextStageNotRestricted
                |> List.append lRulesAboutQuestions
                |> List.append lRulesInteractingWithGps
                |> List.append lRulesInteractingWithCreditsInfo
                |> List.append lRulesMakeFinalPaperAppearAfterAllQuestionsAnswered
                |> List.append lRulesAboutQuestionsAllQuestionsAnsweredButOne
                -- warns that player should move to final stage after final question is correctly answered
                |> List.append lRuleInteractingWithFinalPaper
                |> List.append lRuleGameHasEnded
    in
        lRules
            |> Dict.fromList
