
oci vault secret schedule-secret-deletion --secret-id $VAULT_SECRET_OCIR_HOST_OCID --time-of-deletion "`date --rfc-3339="seconds"`"