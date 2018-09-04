module TranslationHelper exposing (..)

import Dict exposing (Dict)


getInLanguage : String -> String -> String
getInLanguage lgId theStr =
    let
        translationDict : Dict ( String, String ) String
        translationDict =
            Dict.fromList
                [ ( ( "___investigator___", "pt" ), "Investigador" )
                , ( ( "___investigator___", "en" ), "Investigator" )
                , ( ( "___QUESTION_ANSWERED___", "pt" ), "Questão Respondida  " )
                , ( ( "___QUESTION_ANSWERED___", "en" ), "Question Answered  " )
                , ( ( "___YOUR_ANSWER___", "pt" ), "resposta :  " )
                , ( ( "___YOUR_ANSWER___", "en" ), "answer :  " )
                , ( ( "___YOUR_CHOICE___", "pt" ), "escolha :  " )
                , ( ( "___YOUR_CHOICE___", "en" ), "your choice :  " )
                , ( ( "___CORRECT_ANSWER___", "pt" ), "  \nResposta Correcta" )
                , ( ( "___CORRECT_ANSWER___", "en" ), "  \nCorrect Answer" )
                , ( ( "___INCORRECT_ANSWER___", "pt" ), "  \nResposta Incorrecta" )
                , ( ( "___INCORRECT_ANSWER___", "en" ), "  \nIncorrect Answer" )
                , ( ( "__Characters_here__", "pt" ), "Personagens aqui: " )
                , ( ( "__Characters_here__", "en" ), "Characters here: " )
                , ( ( "__Items_here__", "pt" ), "Items aqui: " )
                , ( ( "__Items_here__", "en" ), "Items here: " )
                , ( ( "__Nothing_here__", "pt" ), "Nada aqui." )
                , ( ( "__Nothing_here__", "en" ), "Nothing here." )
                , ( ( "__and__", "pt" ), " e " )
                , ( ( "__and__", "en" ), " and " )
                , ( ( "__Inventory__", "pt" ), "Inventário" )
                , ( ( "__Inventory__", "en" ), "Inventory" )
                , ( ( "___Language___", "pt" ), "Linguagem" )
                , ( ( "___Language___", "en" ), "Language" )
                , ( ( "___Settings___", "pt" ), "Settings" )
                , ( ( "___Settings___", "en" ), "Settings" )
                , ( ( "___AUDIO___", "pt" ), "Audio" )
                , ( ( "___AUDIO___", "en" ), "Audio" )
                , ( ( "___SAVE_LOAD___", "pt" ), "Save/Load" )
                , ( ( "___SAVE_LOAD___", "en" ), "Save/Load" )
                , ( ( "___Check_gps_coords___", "pt" ), "verificar coords" )
                , ( ( "___Check_gps_coords___", "en" ), "check gps coords" )
                , ( ( "___LAYOUT_OPTIONS___", "pt" ), "Layout" )
                , ( ( "___LAYOUT_OPTIONS___", "en" ), "Layout" )
                , ( ( "___NR_TRIES_LEFT___", "pt" ), "numero de tentativas disponíveis : " )
                , ( ( "___NR_TRIES_LEFT___", "en" ), "number of tries left :" )
                , ( ( "___more___", "pt" ), "mais" )
                , ( ( "___more___", "en" ), "more" )
                , ( ( "___Checking_Answer___", "pt" ), "A verificar a resposta.  \nse o dinossauro :) estiver a dormir  \npode demorar até 10 seg. Por favor aguarde ... )" )
                , ( ( "___Checking_Answer___", "en" ), "Checking Answer.  \nIf dynosaur :) is sleeping  \nit can take up to 10 sec. Please be patient ... ) " )
                , ( ( "___Couldnt_check_Answer___", "pt" ), "Não foi possivel verificar a resposta. Por favor tente novamente ! " )
                , ( ( "___Couldnt_check_Answer___", "en" ), "Couldnt check Answer , Please try Again ! " )
                , ( ( "___MAX_TRIES_ON_BACKEND___", "pt" ), "Não foi possivel verificar a resposta.  \nDemasiadas tentativas a partir deste IP .  \nPor favor tente dentro de algumas horas ! " )
                , ( ( "___MAX_TRIES_ON_BACKEND___", "en" ), "Couldnt check Answer.  \nToo Many Tries coming from this IP .  \n Please try Again in a few hours ! " )
                , ( ( "___REACH_MAX_NR_TRIES___", "pt" ), "O numero máximo de tentativas foi atingido !" )
                , ( ( "___REACH_MAX_NR_TRIES___", "en" ), "You reached the maximum number of tries !" )
                , ( ( "___type_answer___", "pt" ), "digite a resposta" )
                , ( ( "___type_answer___", "en" ), "type answer" )
                , ( ( "___SUGGESTED_INTERACTION___", "pt" ), "interacção sugerida :" )
                , ( ( "___SUGGESTED_INTERACTION___", "en" ), "suggested interaction" )
                , ( ( "___center_coords_of_current_location___", "pt" ), "coordenadas centrais do presente local :" )
                , ( ( "___center_coords_of_current_location___", "en" ), "center coords of current location : " )
                , ( ( "___DISTANCE_TO___", "pt" ), "Distância a " )
                , ( ( "___DISTANCE_TO___", "en" ), "Distance to " )
                , ( ( "___IS___", "pt" ), " é :" )
                , ( ( "___IS___", "en" ), " is : " )
                , ( ( "___METERS___", "pt" ), "metros" )
                , ( ( "___METERS___", "en" ), "meters" )
                , ( ( "___EXIT___", "pt" ), "Exit" )
                , ( ( "___EXIT___", "en" ), "Exit" )
                ]

        lgId_ =
            if lgId == "vi" || lgId == "vw" then
                "en"
            else
                lgId
    in
        case (Dict.get ( theStr, lgId_ ) translationDict) of
            Nothing ->
                theStr

            Just str ->
                str
