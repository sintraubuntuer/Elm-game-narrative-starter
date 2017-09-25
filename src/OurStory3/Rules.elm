module OurStory3.Rules exposing (..)

import Engine exposing (..)
import Components exposing (..)
import Dict exposing (Dict)
import OurStory3.Narrative as Narrative


--import Audio

import ClientTypes exposing (AudioFileInfo)


numberOfDesiredStages : Int
numberOfDesiredStages =
    10


questionsAndOrOptionsOnEveryStageExcept : List Int
questionsAndOrOptionsOnEveryStageExcept =
    []


correctAnswerNotRequiredToMove : List Int
correctAnswerNotRequiredToMove =
    [ 3 ]



--import Types exposing (..)


{-| This specifies the initial story world model. At a minimum, you need to set a starting location with the `moveTo` command. You may also want to place various items and characters in different locations. You can also specify a starting scene if required.
-}
startingState : List Engine.ChangeWorldCommand
startingState =
    [ moveTo "onceUponAtime"
    , moveCharacterToLocation "playerOne" "onceUponAtime"
    , moveItemToLocation "gps" "stage1"
    , moveItemToLocationFixed "creditsInfo" ("stage" ++ (toString numberOfDesiredStages))
    ]
        ++ moveQuestionsToStagesFixed
        ++ makeQuestionsAmultiChoice [ ( 201, True ), ( 202, True ), ( 301, True ), ( 401, True ), ( 402, True ), ( 701, True ) ]
        ++ makeStageQuestionsWritableExcept [ 201, 202, 301, 401, 402, 701 ]
        ++ moveMultiOptionsToStagesFixed


getAllStageNrs : List Int
getAllStageNrs =
    List.range 1 numberOfDesiredStages


getQuestionId : Int -> String
getQuestionId nr =
    "question" ++ toString nr


getOptionId : Int -> String
getOptionId nr =
    "option" ++ toString nr


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


makeQuestionsAmultiChoice : List ( Int, Bool ) -> List Engine.ChangeWorldCommand
makeQuestionsAmultiChoice ltupQuestionNrs =
    let
        createForOneElem ( questionNr, bmakeUnwritable ) =
            [ createAmultiChoice (Narrative.getQuestionAvailableChoicesDict questionNr) (getQuestionId questionNr) ]
                ++ if bmakeUnwritable then
                    [ makeItemUnwritable (getQuestionId questionNr) ]
                   else
                    []
    in
        List.map createForOneElem ltupQuestionNrs
            |> List.concat


getQuestionNrsByStageNr : Int -> List Int
getQuestionNrsByStageNr stageNr =
    Dict.get stageNr Narrative.theStagesExtraInfo
        |> Maybe.map .questionsList
        |> Maybe.withDefault []


getQuestionIdsByStageNr : Int -> List String
getQuestionIdsByStageNr stageNr =
    stageNr
        |> getQuestionNrsByStageNr
        |> List.map getQuestionId


getOptionNrsByStageNr : Int -> List Int
getOptionNrsByStageNr stageNr =
    Dict.get stageNr Narrative.theStagesExtraInfo
        |> Maybe.map .optionsList
        |> Maybe.withDefault []


getOptionIdsByStageNr : Int -> List String
getOptionIdsByStageNr stageNr =
    stageNr
        |> getOptionNrsByStageNr
        |> List.map getOptionId



{-
   getAllQuestionsNrs :  List Int
   getAllQuestionsNrs  =
       allStageNrs
       |> List.map getQuestionNrsByStageNr
       |> List.concat


   getAllQuestionsIds :   List String
   getAllQuestionsIds  =
       getAllStageNrs
       |> getAllQuestionsNrs
       |> List.map getQuestionId

-}


getStageQuestionIds : List String
getStageQuestionIds =
    getAllStageNrs
        |> List.map getQuestionIdsByStageNr
        |> List.concat


getFilteredStageQuestionIds : List String
getFilteredStageQuestionIds =
    getAllStageNrs
        |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
        |> List.map getQuestionIdsByStageNr
        |> List.concat


getStageQuestionNrs : List Int
getStageQuestionNrs =
    getAllStageNrs
        |> List.map getQuestionNrsByStageNr
        |> List.concat


getFilteredStageQuestionNrs : List Int
getFilteredStageQuestionNrs =
    getAllStageNrs
        |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
        |> List.map getQuestionNrsByStageNr
        |> List.concat


getStageOptionNrs : List Int
getStageOptionNrs =
    getAllStageNrs
        |> List.map getOptionNrsByStageNr
        |> List.concat


getStageOptionIds : List String
getStageOptionIds =
    getAllStageNrs
        |> List.map getOptionIdsByStageNr
        |> List.concat


getFilteredStageMultiOptionNrs : List Int
getFilteredStageMultiOptionNrs =
    getAllStageNrs
        |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
        |> List.map getOptionNrsByStageNr
        |> List.concat


getFilteredStageMultiOptionIds : List String
getFilteredStageMultiOptionIds =
    getAllStageNrs
        |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
        |> List.map getOptionIdsByStageNr
        |> List.concat


getListOfStageIdWithQuestions : List String
getListOfStageIdWithQuestions =
    getAllStageNrs
        |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
        |> List.map getStageId


getListOfStageNrsWithQuestions : List Int
getListOfStageNrsWithQuestions =
    getAllStageNrs
        |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))


moveQuestionsToStagesFixed : List Engine.ChangeWorldCommand
moveQuestionsToStagesFixed =
    let
        moveQuestionsToStageNr : Int -> List Engine.ChangeWorldCommand
        moveQuestionsToStageNr stageNr =
            let
                lquestionIds =
                    getQuestionIdsByStageNr stageNr

                stageId =
                    getStageId stageNr
            in
                List.map (\x -> moveItemToLocationFixed x stageId) lquestionIds
    in
        getAllStageNrs
            |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
            |> List.map moveQuestionsToStageNr
            |> List.concat


moveMultiOptionsToStagesFixed : List Engine.ChangeWorldCommand
moveMultiOptionsToStagesFixed =
    let
        moveMultiOptionsToStageNr : Int -> List Engine.ChangeWorldCommand
        moveMultiOptionsToStageNr stageNr =
            let
                loptionIds =
                    getOptionIdsByStageNr stageNr

                lIdAndNrs =
                    getOptionNrsByStageNr stageNr
                        |> List.map (\x -> ( getOptionId x, x ))

                stageId =
                    getStageId stageNr

                cwcmds1 =
                    loptionIds
                        |> List.map (\id -> moveItemToLocationFixed id stageId)

                cwcmds2 =
                    lIdAndNrs
                        |> List.map (\( id, nr ) -> createAmultiChoice (Narrative.getMultiOptionAvailableChoicesDict nr) id)
            in
                List.append cwcmds1 cwcmds2
    in
        getAllStageNrs
            |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
            |> List.map moveMultiOptionsToStageNr
            |> List.concat


makeQuestionsWritableExcept : List Int -> List Engine.ChangeWorldCommand
makeQuestionsWritableExcept lnotWritable =
    let
        makeItWritable n =
            makeItemWritable (getQuestionId n)
    in
        getStageQuestionNrs
            |> List.filter (\x -> not (List.member x lnotWritable))
            |> List.map makeItWritable


makeStageQuestionsWritableExcept : List Int -> List Engine.ChangeWorldCommand
makeStageQuestionsWritableExcept lnotWritable =
    let
        makeItWritable n =
            makeItemWritable (getQuestionId n)
    in
        getFilteredStageQuestionNrs
            |> List.filter (\x -> not (List.member x lnotWritable))
            |> List.map makeItWritable


makeAllQuestionsWritable : List Engine.ChangeWorldCommand
makeAllQuestionsWritable =
    makeQuestionsWritableExcept []


backendAnswerCheckerUrl : String
backendAnswerCheckerUrl =
    "http://127.0.0.1:5000/questions/"



--"https://serrot73.pythonanywhere.com/questions/"
--"https://questionanswerntapp.herokuapp.com/questions/"


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
standardRulesTryMoveToNplusOneAndFail : Int -> List Entity
standardRulesTryMoveToNplusOneAndFail stageNr =
    -- if one of the stage questions is not answered
    -- or one of the stage options is not chosen
    -- fails to move to the next stage
    let
        stageQuestionNrs =
            getQuestionNrsByStageNr stageNr

        stageOptionNrs =
            getOptionNrsByStageNr stageNr

        ruleForFailOnQuestionNr : Int -> Entity
        ruleForFailOnQuestionNr questionNr =
            rule ("interacting with higher Stage " ++ toString (stageNr + 1) ++ "  and failing because wrong answer on question " ++ toString questionNr)
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

        ruleForFailOnOptionNr : Int -> Entity
        ruleForFailOnOptionNr optionNr =
            rule ("interacting with higher Stage " ++ toString (stageNr + 1) ++ "  and failing because no choice made so far on option " ++ toString optionNr)
                { interaction = with (getStageId (stageNr + 1))
                , conditions =
                    [ currentLocationIs (getStageId stageNr)
                    , characterIsInLocation "playerOne" (getStageId stageNr)
                    , noChosenOptionYet (getOptionId optionNr)
                    ]
                , changes =
                    []
                }
                (Narrative.interactingWithStageNDict (stageNr + 1) "withoutPreviousAnswered")
    in
        List.map ruleForFailOnQuestionNr stageQuestionNrs
            |> List.append (List.map ruleForFailOnOptionNr stageOptionNrs)


{-| type of rule we should use when we want the player to be able to move to stage N+1 only after
answering correctly to all the questions at stage N and also answering to the presented Options
-}
standardRuleMoveToNplusOneRestricted : Int -> Entity
standardRuleMoveToNplusOneRestricted stageNr =
    -- all stage questions must be answered
    -- all stage options must be answered
    rule ("interacting with Stage " ++ toString (stageNr + 1) ++ " from lower correct answer required")
        { interaction = with (getStageId (stageNr + 1))
        , conditions =
            getQuestionIdsByStageNr stageNr
                |> List.map itemIsCorrectlyAnswered
                |> List.append [ currentLocationIs (getStageId stageNr) ]
                |> List.append [ characterIsInLocation "playerOne" (getStageId stageNr) ]
                |> List.append
                    (getOptionIdsByStageNr stageNr
                        |> List.map choiceHasAlreadyBeenMade
                    )
        , changes =
            [ moveTo (getStageId (stageNr + 1))
            , moveCharacterToLocation "playerOne" (getStageId (stageNr + 1))
            ]
        }
        (Narrative.interactingWithStageNDict (stageNr + 1) "defaultStageDescription")


{-| Same as above , but in this case no answer or correct answer to a question or option is required
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

        --stageNr = questionNr
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
                        -- whether to show feedback about answer ( correct or incorrect )
                        True
                        -- Additional text dict ( in several languages) to show if question is correctly answered)
                        (Narrative.additionalTextIfAnswerCorrectDict questionNr)
                        -- Additional text dict ( in several languages) to add if question is incorrectly answered
                        (Narrative.additionalTextIfAnswerIncorrectDict questionNr)
                        -- List of attributes we want to create in the question ( Item ) if question is correctly answered
                        []
                        []
                    )
                    (getQuestionId questionNr)

                --  questionId
                --simpleCheck_IfAnswerCorrect  correctAnswers (Just 5)  ( "question" ++ toString questionNr )
                ]
            }
            (Narrative.interactingWithQuestionDict questionNr)


interactionWithQuestionNrAllQuestionsAndOptionsAnsweredButThisOne : ( Int, Int ) -> Entity
interactionWithQuestionNrAllQuestionsAndOptionsAnsweredButThisOne ( questionNr, stageNr ) =
    let
        correctAnswers =
            (Narrative.getQuestionAnswers questionNr)

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
                getFilteredStageQuestionIds
                    |> List.filter (\x -> x /= getQuestionId questionNr)
                    |> List.map itemIsCorrectlyAnswered
                    |> List.append [ itemIsOffScreen "finalPaper" ]
                    |> List.append (getFilteredStageMultiOptionIds |> List.map choiceHasAlreadyBeenMade)
            , changes =
                []
            , quasiChanges =
                [ check_IfAnswerCorrect
                    (Narrative.getQuestionAnswers questionNr)
                    (checkAnswerData
                        (Narrative.getQuestionsMaxNrTries questionNr)
                        caseInsensitiveAnswer
                        answerSpacesDontMatter
                        True
                        (Narrative.additionalTextIfAnswerCorrectDict questionNr)
                        (Narrative.additionalTextIfAnswerIncorrectDict questionNr)
                        ([ ( "warningMessage", aDictStringString Narrative.goodNewsMessageAfterAllQuestionsAnsweredDict ) ] ++ lsuggestedInteractionIfLastStage)
                        additionalTextForStages
                    )
                    (getQuestionId questionNr)

                --simpleCheck_IfAnswerCorrect  correctAnswers   ( Narrative.getQuestionsMaxNrTries questionNr )  ( "question" ++ toString questionNr )
                ]
            }
            (Narrative.interactingWithQuestionDict questionNr)


standardInteractionWithMultiOptionNr : Int -> Entity
standardInteractionWithMultiOptionNr optionNr =
    let
        lpossibleChoices =
            Narrative.getMultiOptionAvailableChoicesValList optionNr

        optionId =
            getOptionId optionNr

        allCheckAndActs =
            List.map
                (\x ->
                    checkAndAct_IfChosenOptionIs
                        (checkOptionData
                            x
                            Dict.empty
                            []
                            []
                        )
                        optionId
                )
                lpossibleChoices
    in
        ruleWithQuasiChange ("view multi option" ++ toString optionNr)
            { interaction = with (optionId)
            , conditions =
                []
            , changes = []
            , quasiChanges =
                allCheckAndActs

            --simpleCheck_IfAnswerCorrect  correctAnswers (Just 5)  ( "question" ++ toString questionNr )
            }
            (Narrative.interactingWithMultiOptionDict optionNr)


interactionWithOptionNrAllQuestionsAndOptionsAnsweredButThisOne : ( Int, Int ) -> Entity
interactionWithOptionNrAllQuestionsAndOptionsAnsweredButThisOne ( optionNr, stageNr ) =
    let
        lpossibleChoices : List String
        lpossibleChoices =
            Narrative.getMultiOptionAvailableChoicesValList optionNr

        optionId =
            getOptionId optionNr

        lsuggestedInteractionIfLastStage =
            if stageNr == getLastStageNr then
                [ ( "suggestedInteraction", astring "finalPaper" ) ]
            else
                []

        additionalTextForStages =
            List.range 1 (numberOfDesiredStages - 1)
                |> List.map getStageId
                |> List.map (\x -> ( x, "additionalTextDict", aDictStringString Narrative.additionalStageInfoAfterAllQuestionsAnsweredDict ))

        allCheckAndActs =
            List.map
                (\x ->
                    checkAndAct_IfChosenOptionIs
                        (checkOptionData
                            x
                            Dict.empty
                            ([ ( "warningMessage", aDictStringString Narrative.goodNewsMessageAfterAllQuestionsAnsweredDict ) ] ++ lsuggestedInteractionIfLastStage)
                            additionalTextForStages
                        )
                        optionId
                )
                lpossibleChoices
    in
        ruleWithQuasiChange ("view option" ++ toString optionNr ++ " all options chosen but this one ")
            { interaction = with (optionId)
            , conditions =
                getFilteredStageMultiOptionIds
                    |> List.filter (\x -> x /= optionId)
                    |> List.map choiceHasAlreadyBeenMade
                    |> List.append [ itemIsOffScreen "finalPaper" ]
                    |> List.append (getFilteredStageQuestionIds |> List.map itemIsCorrectlyAnswered)
            , changes =
                []
            , quasiChanges =
                allCheckAndActs

            --simpleCheck_IfAnswerCorrect  correctAnswers (Just 5)  ( "question" ++ toString questionNr )
            }
            (Narrative.interactingWithMultiOptionDict optionNr)


standardRuleMoveToNminusOne : Int -> Entity
standardRuleMoveToNminusOne stageNr =
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


ruleForMultiChoiceAnswer : Entity
ruleForMultiChoiceAnswer =
    ruleWithQuasiChange ("interacting with multichoice answer on stage4")
        { interaction = with "multiChoiceQuestion"
        , conditions =
            [ currentLocationIs "stage4"
            ]
        , changes = []
        , quasiChanges =
            [ check_IfAnswerCorrect
                [ "yes" ]
                (checkAnswerData
                    (Just 10)
                    caseInsensitiveAnswer
                    answerSpacesDontMatter
                    True
                    (Dict.fromList [ ( "pt", "Muito Bem" ), ( "en", "Very Good" ) ])
                    Dict.empty
                    []
                    []
                )
                "multiChoiceQuestion"
            ]
        }
        (Narrative.interactingWithMultiChoiceQuestionDict)


ruleForMultiChoiceOption1 : Entity
ruleForMultiChoiceOption1 =
    ruleWithQuasiChange ("interacting with multichoice options  on stage6")
        { interaction = with "multiChoiceOption1"
        , conditions =
            [ currentLocationIs "stage6"
            ]
        , changes = []
        , quasiChanges =
            [ -- (List String) (Maybe Int) String (List (String , AttrTypes) ) ID
              checkAndAct_IfChosenOptionIs (checkOptionData "yes" (Dict.fromList [ ( "pt", "Muito Bem, és muito forte" ), ( "en", "Very Good , you are a very strong person" ) ]) [] []) "multiChoiceOption1"
            , checkAndAct_IfChosenOptionIs (checkOptionData "no" (Dict.fromList [ ( "pt", "de certeza que queres desistir ?" ), ( "en", "Are you sure you want to quit ?" ) ]) [] []) "multiChoiceOption1"
            , checkAndAct_IfChosenOptionIs (checkOptionData "maybe" (Dict.fromList [ ( "pt", "como é possível não saber ??" ), ( "en", "how can you not know ??" ) ]) [] []) "multiChoiceOption1"
            ]
        }
        (Narrative.interactingWithMultiChoiceOptionAtStage6Dict "")


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


lRulesMakeFinalPaperAppearAfterAllQuestionsAnswered : List Entity
lRulesMakeFinalPaperAppearAfterAllQuestionsAnswered =
    [ rule "final paper appears player moving from penultimate stage to last stage"
        { interaction = with getLastStageId
        , conditions =
            getFilteredStageQuestionIds
                |> List.map itemIsCorrectlyAnswered
                |> List.append (getFilteredStageMultiOptionIds |> List.map choiceHasAlreadyBeenMade)
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
            getFilteredStageQuestionIds
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
            getAllStageNrs

        lRulesToTryMoveToNextStageAndFail =
            List.take ((List.length listOfStageNrs) - 1) listOfStageNrs
                |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
                |> List.filter (\x -> not (List.member x correctAnswerNotRequiredToMove))
                |> List.map standardRulesTryMoveToNplusOneAndFail
                |> List.concat

        lRulesToMoveToNextStageRestricted =
            List.take ((List.length listOfStageNrs) - 1) listOfStageNrs
                |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
                |> List.filter (\x -> not (List.member x correctAnswerNotRequiredToMove))
                |> List.map standardRuleMoveToNplusOneRestricted

        lRulesToMoveToNextStageNotRestricted =
            List.take ((List.length listOfStageNrs) - 1) listOfStageNrs
                |> List.filter
                    (\x ->
                        (List.member x questionsAndOrOptionsOnEveryStageExcept
                            || List.member x correctAnswerNotRequiredToMove
                        )
                    )
                -- theres's no restriction when moving from stage0 ("onceuponatime") to stage1
                |> List.append [ 0 ]
                |> List.map standardRuleMoveToNplusOneNotRestricted

        lRulesToMoveToPreviousStage =
            List.tail listOfStageNrs
                |> Maybe.withDefault []
                |> List.map standardRuleMoveToNminusOne

        lRulesAboutQuestions =
            getAllStageNrs
                |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
                |> List.map getQuestionNrsByStageNr
                |> List.concat
                |> List.map standardInteractionWithQuestionNr

        lRulesAboutMultiOptions =
            getAllStageNrs
                |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
                |> List.map getOptionNrsByStageNr
                |> List.concat
                |> List.map standardInteractionWithMultiOptionNr

        lRulesAboutQuestionsAllQuestionsAndOptionsAnsweredButOne =
            getAllStageNrs
                |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
                |> List.map (\x -> ( x, getQuestionNrsByStageNr x ))
                |> List.map (\( x, ly ) -> List.map (\yelem -> ( yelem, x )) ly)
                |> List.concat
                |> List.map interactionWithQuestionNrAllQuestionsAndOptionsAnsweredButThisOne

        lRulesAboutOptionsAllQuestionsAndOptionsAnsweredButOne =
            getAllStageNrs
                |> List.filter (\x -> not (List.member x questionsAndOrOptionsOnEveryStageExcept))
                |> List.map (\x -> ( x, getOptionNrsByStageNr x ))
                |> List.map (\( x, ly ) -> List.map (\yelem -> ( yelem, x )) ly)
                |> List.concat
                |> List.map interactionWithOptionNrAllQuestionsAndOptionsAnsweredButThisOne

        lRules =
            List.append lRulesToMoveToNextStageRestricted lRulesToMoveToPreviousStage
                |> List.append lRulesToTryMoveToNextStageAndFail
                |> List.append lRulesToMoveToNextStageNotRestricted
                |> List.append lRulesAboutQuestions
                |> List.append lRulesAboutMultiOptions
                |> List.append lRulesInteractingWithGps
                |> List.append [ ruleForMultiChoiceAnswer ]
                |> List.append [ ruleForMultiChoiceOption1 ]
                |> List.append lRulesInteractingWithCreditsInfo
                |> List.append lRulesMakeFinalPaperAppearAfterAllQuestionsAnswered
                -- warns that player should move to final stage after final question is correctly answered
                |> List.append lRulesAboutQuestionsAllQuestionsAndOptionsAnsweredButOne
                |> List.append lRulesAboutOptionsAllQuestionsAndOptionsAnsweredButOne
                |> List.append lRuleInteractingWithFinalPaper
                |> List.append lRuleGameHasEnded
    in
        lRules
            |> Dict.fromList
