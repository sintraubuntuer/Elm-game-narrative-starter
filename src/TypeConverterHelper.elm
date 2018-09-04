module TypeConverterHelper exposing (..)


import Types exposing ( AttrTypes(..)  )
import Dict exposing (Dict)


sendToDebug : Bool -> String -> a -> a
sendToDebug doDebug valStr returnVal =
    case doDebug of
        True ->
            let
                _ = Debug.log valStr returnVal
            in
                returnVal
        False ->
            returnVal


mbAttributeToMbBool :   Bool -> Maybe AttrTypes -> Maybe Bool
mbAttributeToMbBool doDebug mbAttrVal  =
    case mbAttrVal of
        Nothing ->
            Nothing
        Just (Abool b) ->
            Just b
        _ ->
            Nothing
            |> sendToDebug doDebug "Trying to convert an attribute which is not of type Astring to a string"


mbAttributeToBool : Bool -> Maybe AttrTypes ->  Bool
mbAttributeToBool doDebug mbAttrVal  =
    mbAttributeToMbBool doDebug mbAttrVal
    |> Maybe.withDefault False



mbAttributeToMbString :   Bool -> Maybe AttrTypes -> Maybe String
mbAttributeToMbString doDebug mbAttrVal  =
    case mbAttrVal of
        Nothing ->
            Nothing
        Just (Astring theStr) ->
            Just theStr
        _ ->
            Nothing
            |> sendToDebug doDebug "Trying to convert an attribute which is not of type Astring to a string"


mbAttributeToString : Bool -> Maybe AttrTypes ->  String
mbAttributeToString doDebug mbAttrVal  =
    mbAttributeToMbString doDebug mbAttrVal
    |> Maybe.withDefault ""


mbAttributeToMbListString : Bool ->  Maybe AttrTypes  -> Maybe (List String)
mbAttributeToMbListString doDebug mbAttrVal =
    case mbAttrVal of
        Nothing ->
            Nothing
        Just (AListString lstrs) ->
            Just lstrs
        _ ->
            Nothing
            |> sendToDebug doDebug "Trying to convert an attribute which is not of type AListString to a List of strings"


mbAttributeToListString : Bool -> Maybe AttrTypes  ->  List String
mbAttributeToListString doDebug mbAttrVal =
    mbAttributeToMbListString doDebug mbAttrVal
    |> Maybe.withDefault []


mbAttributeToMbListStringString :  Bool -> Maybe AttrTypes  -> Maybe (List (String , String ))
mbAttributeToMbListStringString doDebug mbAttrVal =
    case mbAttrVal of
        Nothing ->
            Nothing
        Just (AListStringString lstrstrs) ->
            Just lstrstrs
        _ ->
            Nothing
            |> sendToDebug doDebug "Trying to convert an attribute which is not of type AListStringString to a List of tuples (string , string )"

mbAttributeToListStringString : Bool ->  Maybe AttrTypes  ->  List (String , String )
mbAttributeToListStringString doDebug mbAttrVal =
    mbAttributeToMbListStringString doDebug mbAttrVal
    |> Maybe.withDefault []


mbAttributeToMbDictStringString : Bool ->  Maybe AttrTypes  ->  Maybe (Dict String String)
mbAttributeToMbDictStringString doDebug mbAttrVal =
    case mbAttrVal of
        Nothing ->
            Nothing
        Just (ADictStringString dstrstr ) ->
            Just dstrstr
        _ ->
            Nothing
            |>  sendToDebug doDebug "Trying to convert an attribute which is not of type ADictStringString to a Dict String String"


mbAttributeToDictStringString : Bool -> Maybe AttrTypes  ->  Dict String String
mbAttributeToDictStringString doDebug mbAttrVal =
    mbAttributeToMbDictStringString doDebug mbAttrVal
    |> Maybe.withDefault Dict.empty


mbAttributeToMbDictStringListStringString : Bool -> Maybe AttrTypes  ->  Maybe (Dict String (List (String , String )))
mbAttributeToMbDictStringListStringString doDebug mbAttrVal =
    case  mbAttrVal of
        Nothing ->
            Nothing
        Just (ADictStringLSS ds ) ->
            Just ds
        _ ->
            Nothing
            |> sendToDebug doDebug "Trying to convert an attribute which is not of type ADictStringLSS to a Dict String (List (String , String )) "


mbAttributeToDictStringListStringString : Bool -> Maybe AttrTypes  ->   Dict String (List (String , String ))
mbAttributeToDictStringListStringString doDebug mbAttrVal =
    mbAttributeToMbDictStringListStringString doDebug mbAttrVal
    |> Maybe.withDefault Dict.empty
