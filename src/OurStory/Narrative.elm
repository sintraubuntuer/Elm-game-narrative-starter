module OurStory.Narrative exposing (..)

import ClientTypes exposing (..)
import Dict exposing (Dict)
import Set


{- These are  the languages for which it is mandatory  to generate  narrative content regarding each interaction
   if  no narrative content exists some default is used
   like for instance the  entity description defined in the manifest
-}


desiredLanguages : List String
desiredLanguages =
    [ "pt", "en" ]



{- These are the languages that are displayed in the sidebar and the user can choose from
   These are  initial values , but they might eventually change along the narrative
-}


initialChoiceLanguages : Dict String String
initialChoiceLanguages =
    Dict.fromList
        [ ( "pt", "portuguese" )
        , ( "en", "english" )
        ]


{-| Info to be displayed on StartScreen
-}
startScreenInfo : StartScreenInfo
startScreenInfo =
    { mainImage = "introImage.png"
    , title_line1 = "A Guided Tour Through Vila Sassetti - Sintra"
    , title_line2 = ""
    , byLine = "An Interactive Story by Sintra Ubuntuer"
    , smallIntro = """ a guided tour through Vila Sassetti ( Quinta da Amizade ) - Sintra
                     """
    , tboxNamePlaceholder = "investigator"
    }


endScreenInfo : EndScreenInfo
endScreenInfo =
    { mainImage = "finalImage.png"
    , congratsMessage1 = "Congratulations ! You reached the End ! ..."
    , congratsMessage2 = "You are now a hiking trail Master  :)"
    , endScreenText = """....
                        """
    }



{- Here is where you can write all of your story text, which keeps the Rules.elm file a little cleaner.
   The narrative that you add to a rule will be shown when that rule matches.  If you give a list of strings, each time the rule matches, it will show the next narrative in the list, which is nice for adding variety and texture to your story.
   I sometimes like to write all my narrative content first, then create the rules they correspond to.
   Note that you can use **markdown** in your text!
-}


startingNarratives : Dict String (List StorySnippet)
startingNarratives =
    Dict.fromList
        [ ( "pt", [ startingNarrative ] )
        , ( "en", [ startingNarrativeEn ] )
        ]


{-| The text that will show when the story first starts, before the player interacts with anythin.
-}
startingNarrative : StorySnippet
startingNarrative =
    { interactableName = "Percurso Pedestre Vila Sassetti..."
    , interactableId = "onceUponAtime"
    , isWritable = False
    , interactableCssSelector = "opening"
    , narrative =
        """Num  dia luminoso de Setembro encontras-te na
            bela Vila de Sintra prestes a iniciar o percurso pedestre de Vila Sassetti
            ( Quinta da Amizade )
         """
    , mbAudio = Nothing
    , mbSuggestedInteractionId = Nothing
    , mbSuggestedInteractionName = Nothing
    , isLastInZipper = True
    }


startingNarrativeEn : StorySnippet
startingNarrativeEn =
    { interactableName = "Pedestrian Footpath..."
    , interactableId = "onceUponAtime"
    , isWritable = False
    , interactableCssSelector = "opening"
    , narrative =
        """On a shiny September day you find yourself in the magnificent Vila de Sintra
             about to start Vila Sassetti ( Quinta da Amizade ) pedestrian footpath ...
       """
    , mbAudio = Nothing
    , mbSuggestedInteractionId = Nothing
    , mbSuggestedInteractionName = Nothing
    , isLastInZipper = True
    }


interactingWithPlayerOneDict : Dict String (List String)
interactingWithPlayerOneDict =
    Dict.fromList
        [ ( "pt", interactingWithPlayerOne )
        , ( "en", interactingWithPlayerOneEn )
        ]


interactingWithPlayerOne : List String
interactingWithPlayerOne =
    [ """
 . . .
      """
    ]


interactingWithPlayerOneEn : List String
interactingWithPlayerOneEn =
    [ """
. . .
      """
    ]


type alias LanguageId =
    String


type alias Question =
    { questionBody : String
    , questionName : String
    , additionalTextIfCorrectAnswer : String
    , additionalTextIfIncorrectAnswer : String
    , questionAnswers : List String
    }


theQuestionsDict : Dict ( Int, LanguageId ) Question
theQuestionsDict =
    Dict.fromList
        [ ( ( 1, "pt" )
          , { questionBody = "Próximo da entrada da Vila Sassetti está também a entrada para um outro Parque. De que parque se trata ?"
            , questionName = "questão 1"
            , additionalTextIfCorrectAnswer = """Muito Bem ! A entrada do parque das merendas fica de facto ao lado da entrada para Vila Sassetti !
              """
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "Parque das Merendas", "Merendas" ]
            }
          )
        , ( ( 1, "en" )
          , { questionBody = "Near the entrance of Vila Sassetti is also the entrance to another Park . What's that Park ? "
            , questionName = "question 1"
            , additionalTextIfCorrectAnswer = """Well Done ! The entrance to Parque das Merendas is located right next to the entrance to Vila Sassetti !
              """
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = []
            }
            -- no need to duplicate answers . Just add the ones that eventually make sense in a different language
            -- program will "merge" all the answers lists and accept all as valid regardless of the language
          )
        , ( ( 2, "pt" )
          , { questionBody = "quantos azulejos observas no maior banco  ?"
            , questionName = "questão 2"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = "Vá lá ... Não é uma pergunta difícil ! "
            , questionAnswers = [ "21", "vinte e um" ]
            }
          )
        , ( ( 2, "en" )
          , { questionBody = "How many tiles do you see on the biggest seat  ?"
            , questionName = "question 2"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = "Come on ... That's is not a tough question ! "
            , questionAnswers = [ "twenty one" ]
            }
            -- no need to duplicate answers . Just add the ones that eventually make sense in a different language
            -- program will "merge" all the answers lists (to the same question) and accept all as valid regardless of the language
          )
        , ( ( 3, "pt" )
          , { questionBody = """Quantos pilares consegues contar até ao placard que indica "Casa do Caseiro , Casa Principal , etc ..." """
            , questionName = "questão 3"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "15", "quinze" ]
            }
          )
        , ( ( 3, "en" )
          , { questionBody = """How many pillars can you count from here to the placard with "Casa do Caseiro , Casa Principal , etc ..." written on it """
            , questionName = "question 3"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "fifteen" ]
            }
          )
        , ( ( 4, "pt" )
          , { questionBody = """O relógio de sol indica de que horas a que horas (ex: 9 a 10)?"""
            , questionName = "questão 4"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "8 a 4", "8 as 4", "8-4" ]
            }
          )
        , ( ( 4, "en" )
          , { questionBody = """The sun clock tells the time from what hour of the day to what hour (ex: 9 to 10)?"""
            , questionName = "question 4"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "8 to 4" ]
            }
          )
        , ( ( 5, "pt" )
          , { questionBody = "Qual o nome da planta que se encontra indicado ?"
            , questionName = "questão 5"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "Camellia Japonica", "Camellia Japonica L.", "THEACEAE" ]
            }
          )
        , ( ( 5, "en" )
          , { questionBody = "What's the name of the plant ( written on the sign ) ?"
            , questionName = "question 5"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = []
            }
          )
        , ( ( 6, "pt" )
          , { questionBody = "Parece-te uma cadeira confortável ?"
            , questionName = "questão 6"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "sim", "não", "nao" ]
            }
          )
        , ( ( 6, "en" )
          , { questionBody = "Does it seem like a comfortable chair  ?"
            , questionName = "question 6"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "yes", "no" ]
            }
          )
        , ( ( 7, "pt" )
          , { questionBody = "Quantos troncos ( cortados ) podes observar junto ao rochedo ?"
            , questionName = "questão 7"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "2", "dois" ]
            }
          )
        , ( ( 7, "en" )
          , { questionBody = "how many ( chopped ) logs can you see near the big rock"
            , questionName = "question 7"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "two" ]
            }
          )
        , ( ( 8, "pt" )
          , { questionBody = "Qual a distância indicada ( em metros ) para o Penedo da Amizade ?"
            , questionName = "questão 8"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "115", "cento e quinze" ]
            }
          )
        , ( ( 8, "en" )
          , { questionBody = "What's the distance ( in meters ) to Penedo da Amizade ( Cliff of Amizade ) shown on the sign  ?"
            , questionName = "question 8"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "hundred and fifteen" ]
            }
          )
        , ( ( 9, "pt" )
          , { questionBody = "No topoguia informativo sobre as vias de escalada no Penedo da Amizade qual o Nome da via Nº 7 ?"
            , questionName = "questão 9"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "Funk da Serra" ]
            }
          )
        , ( ( 9, "en" )
          , { questionBody = "What's the name of climbing route Nº 7 shown on  Penedo da Amizade Rock climbing guide  ?"
            , questionName = "question 9"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = []
            }
          )
        , ( ( 10, "pt" )
          , { questionBody = "Logo após a porta de saída está um placard informativo. Qual a distância ( em metros ) para o Palácio da Pena ? "
            , questionName = "questão 10"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "495", "quatrocentos e noventa e cinco" ]
            }
          )
        , ( ( 10, "en" )
          , { questionBody = "right after the door there's an informative sign. What's the distance ( in meters ) to Parque da Pena ( Park of Pena )  ?"
            , questionName = "question 10"
            , additionalTextIfCorrectAnswer = ""
            , additionalTextIfIncorrectAnswer = ""
            , questionAnswers = [ "four hundred and ninety five" ]
            }
          )
        ]


getQuestionsMaxNrTries : Int -> Maybe Int
getQuestionsMaxNrTries questionNr =
    let
        dictMaxTries =
            Dict.fromList
                [ ( 1, Just 5 )
                , ( 2, Just 21 )
                , ( 3, Nothing )
                , ( 4, Just 5 )
                , ( 5, Just 5 )
                , ( 6, Just 5 )
                , ( 7, Just 5 )
                , ( 8, Just 5 )
                , ( 9, Just 5 )
                , ( 10, Just 5 )
                ]
    in
        dictMaxTries
            |> Dict.get questionNr
            |> Maybe.withDefault Nothing


theStagesDict : Dict ( Int, LanguageId ) { stageNarrative : List String, stageName : String }
theStagesDict =
    Dict.fromList
        [ ( ( 1, "pt" )
          , { stageNarrative = [ """
![pic500](img/entradaVilaSassetti.png)

Estás na bonita Vila de Sintra próximo da entrada do percurso pedestre
da Vila Sassetti ( Quinta da Amizade ) ...

"Este percurso pedestre permite o acesso ao Palácio Nacional da Pena e ao Castelo dos Mouros, desde o Centro Histórico de Sintra.

A Vila Sassetti está integrada na Paisagem Cultural de Sintra, classificada como Património da Humanidade pela UNESCO.

O jardim, concebido pelo arquiteto Luigi Manini, procura obedecer a uma estética naturalista, sendo estruturado por um caminho sinuoso que é atravessado por uma linha de água artificial. O jardim expressa a relação de harmonia entre a arquitetura e a paisagem, que assim parecem fundir-se naturalmente."

![pic500](img/entradaVilaSassetti2.png)

![pic500](img/entradaVilaSassetti3.png)
            """ ]
            , stageName = "Stage 1 - Inicio "
            }
          )
        , ( ( 1, "en" )
          , { stageNarrative = [ """
![pic500](img/entradaVilaSassetti.png)

You are in the beautiful village of Sintra near the start of Vila Sassetti Pedestrian Footpath ...

"The Footpath  provides access to the National Palace of Pena and the Moorish Castle from the Historical Centre of Sintra.

Villa Sassetti is integrated into the Cultural Landscape of Sintra, classified as UNESCO World Heritage.

The garden, designed by the architect Luigi Manini, strives to obey a naturalist aesthetic structured around a twisting pathway criss-crossed by an artificial watercourse. The garden expresses the harmonious relationship between architecture and the landscape that seem able to naturally merge into each other. "

![pic500](img/entradaVilaSassetti2.png)

![pic500](img/entradaVilaSassetti3.png)
    """ ]
            , stageName = "Stage 1 - Start"
            }
          )
        , ( ( 2, "pt" )
          , { stageNarrative = [ """
![pic500](img/largo.png)

Estás agora num pequeno largo ... À esquerda ( de quem sobe ) é possível observar um extenso banco com vários pequenos azulejos
e à direita ( de quem sobe ) é possível observar uma espécie de trono

![pic500](img/largo2.png)

          """ ]
            , stageName = "Stage 2 - o largo "
            }
          )
        , ( ( 2, "en" )
          , { stageNarrative = [ """
![pic500](img/largo.png)

you are now on a small round space ... To the left ( when going up ) one can observe a large bank with several small tiles
and to the right ( when going up ) one can observe a sort of throne chair ...

![pic500](img/largo2.png)

          """ ]
            , stageName = "Stage 2"
            }
          )
        , ( ( 3, "pt" )
          , { stageNarrative = [ """
![pic500](img/arcadas.png)
          """ ]
            , stageName = "Stage 3 - arcade"
            }
          )
        , ( ( 3, "en" )
          , { stageNarrative = [ """
![pic500](img/arcadas.png)
          """ ]
            , stageName = "Stage 3 - arcade "
            }
          )
        , ( ( 4, "pt" )
          , { stageNarrative = [ """Estás agora junto ao Edifício Principal ...

![pic500](img/casaPrincipal.png)

" O edifício principal distingue-se pela torre circular central de três pisos ,
a partir da qual se estendem outros corpos de geometria variável
, empregando o granito de Sintra como revestimento exterior principal
, as faixas de terracota características do estilo Românico Lombardo e diversas
peças da coleção de antiquária do comitente "

![pic500](img/casaPrincipalRelogio.png)
            """ ]
            , stageName = "Stage 4 - Edificio Principal"
            }
          )
        , ( ( 4, "en" )
          , { stageNarrative = [ """You are now next to the Main Building ...

![pic500](img/casaPrincipal.png)

"The main building stands out for its central circular tower spanning three storeys
, out of which extend other constructions with variable geometries
, applying Sintra granite as the main exterior finishing material with rows of terracotta
characteristic of the Lombard Romanesque
, alongside diverse pieces from the antiques collection of the owner"

![pic500](img/casaPrincipalRelogio.png)
          """ ]
            , stageName = "Stage 4 - Main Building"
            }
          )
        , ( ( 5, "pt" )
          , { stageNarrative = [ """Estás agora em 5 ... À tua volta vês ...

![pic500](img/camelliaJaponica.png)
            """ ]
            , stageName = "Stage 5 - a Planta"
            }
          )
        , ( ( 5, "en" )
          , { stageNarrative = [ """You are now in stage 5 ... You look around and see ...

![pic500](img/camelliaJaponica.png)
            """ ]
            , stageName = "Stage 5 - the Plant"
            }
          )
        , ( ( 6, "pt" )
          , { stageNarrative = [ """reparas que estás junto a uma enigmática cadeira ...

![pic500](img/cadeira.png)
            """ ]
            , stageName = "Stage 6 - a cadeira"
            }
          )
        , ( ( 6, "en" )
          , { stageNarrative = [ """You notice an enigmatic chair right next to you
![pic500](img/cadeira.png)
            """ ]
            , stageName = "Stage 6 - the Chair"
            }
          )
        , ( ( 7, "pt" )
          , { stageNarrative = [ """
![pic500](img/rochedo1.png)

![pic500](img/rochedo2.png)
          """ ]
            , stageName = "Stage 7 - o Rochedo"
            }
          )
        , ( ( 7, "en" )
          , { stageNarrative = [ """
![pic500](img/rochedo1.png)

![pic500](img/rochedo2.png)
          """ ]
            , stageName = "Stage 7 - the Rock"
            }
          )
        , ( ( 8, "pt" )
          , { stageNarrative = [ """
![pic500](img/portaSaida_.png)

![pic500](img/placardProximoSaida1.png)
             """ ]
            , stageName = "Stage 8 - placard informativo"
            }
          )
        , ( ( 8, "en" )
          , { stageNarrative = [ """
![pic500](img/portaSaida_.png)

![pic500](img/placardProximoSaida1.png)
          """ ]
            , stageName = "Stage 8 - info"
            }
          )
        , ( ( 9, "pt" )
          , { stageNarrative = [ """Estás agora junto a um topoguia sobre as vias de escalada do Penedo da Amizade

![pic500](img/viasPenedoDaAmizade.png)
          """ ]
            , stageName = "Stage 9 - Topoguia"
            }
          )
        , ( ( 9, "en" )
          , { stageNarrative = [ """You are now next to a rock climbing guide that presents some info about Penedo da Amizade climbing routes

![pic500](img/viasPenedoDaAmizade.png)
          """ ]
            , stageName = "Stage 9 - Rock climbing guide"
            }
          )
        , ( ( 10, "pt" )
          , { stageNarrative = [ """Passaste pela  última porta e encontras-te agora no Penedo da Amizade ...

![pic500](img/portaSaida.png)

À tua esquerda encontra-se um placard informativo com distâncias relativamente a alguns pontos de interesse

![pic500](img/placardProximoSaidaDistancias.png)
          """ ]
            , stageName = "Stage 10 - Penedo da Amizade"
            }
          )
        , ( ( 10, "en" )
          , { stageNarrative = [ """You've gone through the last door and are now in Penedo da Amizade ...

![pic500](img/portaSaida.png)

To your left there's info on distances to some Points of Interest

![pic500](img/placardProximoSaidaDistancias.png)
          """ ]
            , stageName = "Stage 10 - Penedo da Amizade"
            }
          )
        ]


getQuestionBody : Int -> LanguageId -> List String
getQuestionBody nr lgId =
    let
        questionsDict =
            theQuestionsDict

        question =
            Dict.get ( nr, lgId ) questionsDict
    in
        question
            |> Maybe.map (.questionBody)
            |> (\x ->
                    case x of
                        Nothing ->
                            []

                        Just qbody ->
                            [ qbody ]
               )


getQuestionBodyAsString : Int -> LanguageId -> String
getQuestionBodyAsString nr lgId =
    getQuestionBody nr lgId
        |> String.join " , "


getQuestionAnswers : Int -> List String
getQuestionAnswers questionNr =
    let
        questionsDict =
            theQuestionsDict

        getLgAnswers : Int -> LanguageId -> List String
        getLgAnswers theQuestionNr lgId =
            Dict.get ( theQuestionNr, lgId ) questionsDict
                |> Maybe.map (.questionAnswers)
                |> (\x ->
                        case x of
                            Nothing ->
                                []

                            Just lans ->
                                lans
                   )

        validAnswers =
            List.map (\lgId -> getLgAnswers questionNr lgId) desiredLanguages
                |> List.concat
                |> Set.fromList
                |> Set.toList
    in
        validAnswers


getQuestionName : Int -> LanguageId -> String
getQuestionName nr lgId =
    let
        questionsDict =
            theQuestionsDict

        question =
            Dict.get ( nr, lgId ) questionsDict
    in
        question
            |> Maybe.map (.questionName)
            |> (\x ->
                    case x of
                        Nothing ->
                            if lgId == "pt" then
                                "questão " ++ (toString nr)
                            else
                                "question " ++ (toString nr)

                        Just qname ->
                            qname
               )


interactingWithQuestionNDict : Int -> Dict String (List String)
interactingWithQuestionNDict nr =
    Dict.fromList
        [ ( "pt", interactingWithQuestion nr "pt" )
        , ( "en", interactingWithQuestion nr "en" )
        ]


interactingWithQuestion : Int -> LanguageId -> List String
interactingWithQuestion questionNr lgId =
    getQuestionBody questionNr lgId


additionalTextIfAnswerCorrectDict : Int -> Dict String String
additionalTextIfAnswerCorrectDict questionNr =
    Dict.fromList
        [ ( "pt", additionalTextIfAnswerCorrect questionNr "pt" )
        , ( "en", additionalTextIfAnswerCorrect questionNr "en" )
        ]


additionalTextIfAnswerCorrect : Int -> LanguageId -> String
additionalTextIfAnswerCorrect questionNr lgId =
    Dict.get ( questionNr, lgId ) theQuestionsDict
        |> Maybe.map (.additionalTextIfCorrectAnswer)
        |> Maybe.withDefault ""


additionalTextIfAnswerIncorrectDict : Int -> Dict String String
additionalTextIfAnswerIncorrectDict questionNr =
    Dict.fromList
        [ ( "pt", additionalTextIfAnswerIncorrect questionNr "pt" )
        , ( "en", additionalTextIfAnswerIncorrect questionNr "en" )
        ]


additionalTextIfAnswerIncorrect : Int -> LanguageId -> String
additionalTextIfAnswerIncorrect questionNr lgId =
    Dict.get ( questionNr, lgId ) theQuestionsDict
        |> Maybe.map (.additionalTextIfIncorrectAnswer)
        |> Maybe.withDefault ""


getTheStageInfo : Int -> LanguageId -> Maybe { stageNarrative : List String, stageName : String }
getTheStageInfo stageNr languageId =
    Dict.get ( stageNr, languageId ) theStagesDict


getStageName : Int -> LanguageId -> String
getStageName stageNr languageId =
    getTheStageInfo stageNr languageId
        |> Maybe.map .stageName
        |> Maybe.withDefault ("Stage " ++ (toString stageNr))


getStageRecord : Int -> LanguageId -> Maybe { withoutPreviousAnswered : List String, defaultStageDescription : List String, enteringFromHigherStage : List String, noQuestionOrNotMandatory : List String }
getStageRecord stageNr lgId =
    let
        theStageDescription : Maybe (List String)
        theStageDescription =
            getTheStageInfo stageNr lgId
                |> Maybe.map .stageNarrative

        getWithoutPreviousAnswered : List String
        getWithoutPreviousAnswered =
            if lgId == "pt" then
                [ "Deves responder à pergunta da etapa "
                    ++ toString (stageNr - 1)
                    ++ " antes de entrar na etapa "
                    ++ toString stageNr
                ]
            else
                [ "You have to answer stage "
                    ++ toString (stageNr - 1)
                    ++ " question "
                    ++ " before being allowed in stage "
                    ++ toString stageNr
                ]

        getEnteringFromHigherStage : String
        getEnteringFromHigherStage =
            if lgId == "pt" then
                "Para terminar o percurso deves seguir na direcção oposta"
            else
                "To finish the course you should move in the opposite direction"

        mbStandardQuestionRecord =
            case theStageDescription of
                Just stageDescription ->
                    Just
                        ({ withoutPreviousAnswered = getWithoutPreviousAnswered
                         , defaultStageDescription = stageDescription
                         , enteringFromHigherStage =
                            stageDescription
                                |> List.map (\x -> getEnteringFromHigherStage ++ "  \n" ++ x)
                         , noQuestionOrNotMandatory = stageDescription
                         }
                        )

                Nothing ->
                    Nothing
    in
        mbStandardQuestionRecord


interactingWithStageNDict : Int -> String -> Dict String (List String)
interactingWithStageNDict n fieldStr =
    Dict.fromList
        [ ( "pt", interactingWithStageN n "pt" fieldStr )
        , ( "en", interactingWithStageN n "en" fieldStr )
        ]


interactingWithStageN : Int -> LanguageId -> String -> List String
interactingWithStageN stageNr lgId fieldStr =
    let
        theRec =
            getStageRecord stageNr lgId
                |> Maybe.withDefault
                    { withoutPreviousAnswered = [ "" ]
                    , defaultStageDescription = [ "" ]
                    , enteringFromHigherStage = [ "" ]
                    , noQuestionOrNotMandatory = [ "" ]
                    }

        theLString =
            if fieldStr == "withoutPreviousAnswered" then
                theRec.withoutPreviousAnswered
            else if fieldStr == "defaultStageDescription" then
                theRec.defaultStageDescription
            else if fieldStr == "enteringFromHigherStage" then
                theRec.enteringFromHigherStage
            else
                theRec.noQuestionOrNotMandatory
    in
        theLString


additionalStageInfoAfterQuestionAnsweredDict : Dict String String
additionalStageInfoAfterQuestionAnsweredDict =
    Dict.fromList
        [ ( "pt", "A questão deste nivel já está respondida ... " )
        , ( "en", "question on this stage is already  answered ... " )
        ]


additionalStageInfoAfterAllQuestionsAnsweredDict : Dict String String
additionalStageInfoAfterAllQuestionsAnsweredDict =
    Dict.fromList
        [ ( "pt", "Todas as questões foram respondidas. Dirige-te para o ultimo nivel ... " )
        , ( "en", "All questions have been answered. Now move to the last stage ... " )
        ]


takeGpsDict : Dict String (List String)
takeGpsDict =
    Dict.fromList
        [ ( "pt", takeGps )
        , ( "en", takeGpsEn )
        ]


takeGps : List String
takeGps =
    [ "Guardas cuidadosamente o Gps " ]


takeGpsEn : List String
takeGpsEn =
    [ """
You carefully pick up and store the gps receiver !
     """ ]


lookAtGpsDict : Dict String (List String)
lookAtGpsDict =
    Dict.fromList
        [ ( "pt", lookAtGps )
        , ( "en", lookAtGpsEn )
        ]


lookAtGps : List String
lookAtGps =
    [ """
Consultas o aparelho receptor de gps :
    """
    ]


lookAtGpsEn : List String
lookAtGpsEn =
    [ """
You look at your gps receiver device :
    """
    ]


goodNewsMessageAfterAllQuestionsAnsweredDict : Dict String String
goodNewsMessageAfterAllQuestionsAnsweredDict =
    Dict.fromList
        [ ( "pt", goodNewsMessageAfterAllQuestionsAnsweredPt )
        , ( "en", goodNewsMessageAfterAllQuestionsAnsweredEn )
        ]


goodNewsMessageAfterAllQuestionsAnsweredPt : String
goodNewsMessageAfterAllQuestionsAnsweredPt =
    """
Respondeste a todas as perguntas ... Procura o papiro no ultimo nivel
       """


goodNewsMessageAfterAllQuestionsAnsweredEn : String
goodNewsMessageAfterAllQuestionsAnsweredEn =
    """
All questions have been answered . Look for an old paper in last stage ...
       """


interactingWithFinalPaperDict : Dict String (List String)
interactingWithFinalPaperDict =
    Dict.fromList
        [ ( "pt", interactingWithFinalPaperPt )
        , ( "en", interactingWithFinalPaperEn )
        ]


interactingWithFinalPaperPt : List String
interactingWithFinalPaperPt =
    [ "Parabéns ! Superaste todos os desafios propostos.  \nEncontarás uma agradável surpresa em ..."
    ]


interactingWithFinalPaperEn : List String
interactingWithFinalPaperEn =
    [ "Congratulations ! You overcome all challenges.  \nYou will find a nice surprise located at ..."
    ]


theCreditsInformationDict : Dict String (List String)
theCreditsInformationDict =
    Dict.fromList
        [ ( "pt", creditsInformation )
        , ( "en", creditsInformation )
        ]


creditsInformation : List String
creditsInformation =
    [ """
### Location Info : ###
http://www.parquesdesintra.pt/


### Elm Language and package ecosystem ###

Evan Czaplicki ,  Richard Feldman , Werner de Groot , Dave Keen ...

### Elm Narrative Engine : ###

Jeff Schomay

( the persons above in no way endorse this particular extension or narrative)

### extensions to the Narrative Engine : ###

Nuno Torres

### Game-Narrative ###

Nuno Torres

    """
    ]


gameHasEndedDict : Dict String (List String)
gameHasEndedDict =
    Dict.fromList
        [ ( "pt", gameHasEnded )
        , ( "en", gameHasEndedEn )
        ]


gameHasEnded : List String
gameHasEnded =
    [ """
Este jogo acabou ! Podes consultar todos os items no teu inventário ,
mas o jogo chegou ao fim ! Diverte-te !
      """
    ]


gameHasEndedEn : List String
gameHasEndedEn =
    [ """
Game has Ended ! You can take a look at your inventory items ( but game has ended ) ! Have Fun !
      """
    ]
