module TypesUpdateHelper exposing (..)

import Types


updateNestedMbInputTextBk : Types.ExtraInfoWithPendingChanges -> Maybe String -> Types.ExtraInfoWithPendingChanges
updateNestedMbInputTextBk extraInfoWithPendingChanges mbInputTextForBackend =
    let
        interactionExtraInfo_ =
            extraInfoWithPendingChanges.interactionExtraInfo

        newinteractionExtraInfo =
            { interactionExtraInfo_ | mbInputTextForBackend = mbInputTextForBackend }

        newExtraInfoWithPendingChanges =
            { extraInfoWithPendingChanges | interactionExtraInfo = newinteractionExtraInfo }
    in
        newExtraInfoWithPendingChanges


updateNestedBkAnsStatus : Types.ExtraInfoWithPendingChanges -> Types.BackendAnswerStatus -> Types.ExtraInfoWithPendingChanges
updateNestedBkAnsStatus extraInfoWithPendingChanges bkAnsStatus =
    let
        interactionExtraInfo_ =
            extraInfoWithPendingChanges.interactionExtraInfo

        newInteractionExtraInfo =
            { interactionExtraInfo_ | bkAnsStatus = bkAnsStatus }

        newExtraInfoWithPendingChanges =
            { extraInfoWithPendingChanges | interactionExtraInfo = newInteractionExtraInfo }
    in
        newExtraInfoWithPendingChanges
