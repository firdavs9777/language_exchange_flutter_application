import React from "react";
import InfoRow from "./InfoRow";
import { Badge } from "react-bootstrap";
import { useTranslation } from "react-i18next";
import { UserProfileData } from "./ProfileTypes/types";


const LanguagesView: React.FC<{ formData: UserProfileData }> = ({ formData }) => {
    const { t } = useTranslation();

  return (
    <div className="py-2">
      <InfoRow
        label={t("profile.labels.native_language")}
        value={
          formData.native_language ? (
            <Badge bg="primary" className="py-2 px-3 fw-normal">
              {formData.native_language}
            </Badge>
          ) : (
            <span className="text-muted fst-italic">
              {t("profile.messages.not_specified")}
            </span>
          )
        }
      />
      <InfoRow
        label={t("profile.labels.learning")}
        value={
          formData.language_to_learn ? (
            <Badge bg="success" className="py-2 px-3 fw-normal">
              {formData.language_to_learn}
            </Badge>
          ) : (
            <span className="text-muted fst-italic">
              {t("profile.messages.not_specified")}
            </span>
          )
        }
      />
    </div>
  );
}

export default LanguagesView