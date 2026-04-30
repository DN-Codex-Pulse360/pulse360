import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldDisplayValue, getFieldValue } from 'lightning/uiRecordApi';

import LEFT_ACCOUNT_FIELD from '@salesforce/schema/Governance_Case__c.Left_Account__c';
import RIGHT_ACCOUNT_FIELD from '@salesforce/schema/Governance_Case__c.Right_Account__c';
import DUPLICATE_CONFIDENCE_FIELD from '@salesforce/schema/Governance_Case__c.Duplicate_Confidence__c';
import CONFIDENCE_BAND_FIELD from '@salesforce/schema/Governance_Case__c.Confidence_Band__c';
import REVIEW_FLAG_FIELD from '@salesforce/schema/Governance_Case__c.Review_Flag__c';
import TOP_MATCH_FEATURES_FIELD from '@salesforce/schema/Governance_Case__c.Top_Match_Features__c';
import FEATURE_EXPLANATIONS_FIELD from '@salesforce/schema/Governance_Case__c.Feature_Explanations__c';
import SOURCE_SNAPSHOT_ID_FIELD from '@salesforce/schema/Governance_Case__c.Source_Snapshot_Id__c';
import MODEL_VERSION_FIELD from '@salesforce/schema/Governance_Case__c.Model_Version__c';
import ATTRIBUTE_VALIDITY_PAYLOAD_FIELD from '@salesforce/schema/Governance_Case__c.Attribute_Validity_Payload__c';
import HIERARCHY_CONFLICT_FIELD from '@salesforce/schema/Governance_Case__c.Hierarchy_Conflict_Flag__c';
import HIERARCHY_IMPACT_FIELD from '@salesforce/schema/Governance_Case__c.Hierarchy_Impact_Summary__c';
import SOURCE_PRODUCT_FIELD from '@salesforce/schema/Governance_Case__c.Source_Product__c';
import TARGET_ENTITY_NAME_FIELD from '@salesforce/schema/Governance_Case__c.Target_Entity_Name__c';
import COUNTRY_CODE_FIELD from '@salesforce/schema/Governance_Case__c.Country_Code__c';
import MARKET_FIELD from '@salesforce/schema/Governance_Case__c.Market__c';
import OFFERING_FAMILY_FIELD from '@salesforce/schema/Governance_Case__c.Offering_Family__c';
import OFFER_BUNDLE_FIELD from '@salesforce/schema/Governance_Case__c.Offer_Bundle__c';
import TARGET_B2B_CUSTOMER_NAMES_FIELD from '@salesforce/schema/Governance_Case__c.Target_B2B_Customer_Names__c';
import RECOMMENDED_NEXT_ACTIONS_FIELD from '@salesforce/schema/Governance_Case__c.Recommended_Next_Actions__c';
import REVIEW_PRIORITY_FIELD from '@salesforce/schema/Governance_Case__c.Review_Priority__c';
import ACTIVATION_BLOCK_REASONS_FIELD from '@salesforce/schema/Governance_Case__c.Activation_Block_Reasons__c';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_EXTERNAL_LEGAL_NAME_FIELD from '@salesforce/schema/Account.External_Legal_Name__c';
import ACCOUNT_EXTERNAL_REGISTRATION_FIELD from '@salesforce/schema/Account.External_Registration_Number__c';
import ACCOUNT_EXTERNALLY_VALIDATED_FIELD from '@salesforce/schema/Account.Externally_Validated__c';
import ACCOUNT_EXTERNAL_VALIDITY_SCORE_FIELD from '@salesforce/schema/Account.Validity_Score_External__c';
import ACCOUNT_AI_CITATION_COUNT_FIELD from '@salesforce/schema/Account.AI_Citation_Count__c';
import ACCOUNT_AI_MODEL_ID_FIELD from '@salesforce/schema/Account.AI_Model_Id__c';

const CASE_FIELDS = [
    LEFT_ACCOUNT_FIELD,
    RIGHT_ACCOUNT_FIELD,
    DUPLICATE_CONFIDENCE_FIELD,
    CONFIDENCE_BAND_FIELD,
    REVIEW_FLAG_FIELD,
    TOP_MATCH_FEATURES_FIELD,
    FEATURE_EXPLANATIONS_FIELD,
    SOURCE_SNAPSHOT_ID_FIELD,
    MODEL_VERSION_FIELD,
    ATTRIBUTE_VALIDITY_PAYLOAD_FIELD,
    HIERARCHY_CONFLICT_FIELD,
    HIERARCHY_IMPACT_FIELD,
    SOURCE_PRODUCT_FIELD,
    TARGET_ENTITY_NAME_FIELD,
    COUNTRY_CODE_FIELD,
    MARKET_FIELD,
    OFFERING_FAMILY_FIELD,
    OFFER_BUNDLE_FIELD,
    TARGET_B2B_CUSTOMER_NAMES_FIELD,
    RECOMMENDED_NEXT_ACTIONS_FIELD,
    REVIEW_PRIORITY_FIELD,
    ACTIVATION_BLOCK_REASONS_FIELD
];

const ACCOUNT_FIELDS = [
    ACCOUNT_NAME_FIELD,
    ACCOUNT_EXTERNAL_LEGAL_NAME_FIELD,
    ACCOUNT_EXTERNAL_REGISTRATION_FIELD,
    ACCOUNT_EXTERNALLY_VALIDATED_FIELD,
    ACCOUNT_EXTERNAL_VALIDITY_SCORE_FIELD,
    ACCOUNT_AI_CITATION_COUNT_FIELD,
    ACCOUNT_AI_MODEL_ID_FIELD
];

export default class Pulse360GovernanceMatchEvidence extends LightningElement {
    @api recordId;

    record;
    error;
    hasWireResolved = false;

    @wire(getRecord, { recordId: '$recordId', optionalFields: CASE_FIELDS })
    wiredRecord({ data, error }) {
        this.hasWireResolved = true;
        if (data) {
            this.record = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }

    @wire(getRecord, { recordId: '$leftAccountId', fields: ACCOUNT_FIELDS })
    leftAccountRecord;

    @wire(getRecord, { recordId: '$rightAccountId', fields: ACCOUNT_FIELDS })
    rightAccountRecord;

    get isLoaded() {
        return Boolean(this.record);
    }

    get isLoading() {
        return !this.hasWireResolved;
    }

    get hasError() {
        return Boolean(this.error);
    }

    get errorMessage() {
        return this.error?.body?.message || 'Unable to load match evidence.';
    }

    get leftAccountId() {
        return this.fieldValue(LEFT_ACCOUNT_FIELD);
    }

    get leftAccountName() {
        return this.lookupAccountLabel(this.leftAccountRecord, this.leftAccountId);
    }

    get leftAccountUrl() {
        return this.recordUrl(this.leftAccountId);
    }

    get rightAccountId() {
        return this.fieldValue(RIGHT_ACCOUNT_FIELD);
    }

    get rightAccountName() {
        return this.lookupAccountLabel(this.rightAccountRecord, this.rightAccountId);
    }

    get rightAccountUrl() {
        return this.recordUrl(this.rightAccountId);
    }

    get isCspReview() {
        return this.fieldValue(SOURCE_PRODUCT_FIELD) === 'csp_smart_city_proposition_readiness';
    }

    get showDuplicateEvidence() {
        return !this.isCspReview;
    }

    get targetEntityName() {
        return this.fieldValue(TARGET_ENTITY_NAME_FIELD) || 'Not available';
    }

    get cspMarket() {
        const market = this.fieldValue(MARKET_FIELD) || 'Market not available';
        const countryCode = this.fieldValue(COUNTRY_CODE_FIELD) || 'N/A';
        return `${market} (${countryCode})`;
    }

    get offeringFamily() {
        return this.fieldValue(OFFERING_FAMILY_FIELD) || 'Not available';
    }

    get offerBundle() {
        return this.fieldValue(OFFER_BUNDLE_FIELD) || 'Not available';
    }

    get targetB2bCustomerNames() {
        return this.fieldValue(TARGET_B2B_CUSTOMER_NAMES_FIELD) || 'No target B2B customers supplied.';
    }

    get recommendedNextActions() {
        return this.fieldValue(RECOMMENDED_NEXT_ACTIONS_FIELD) || 'No recommended next actions supplied.';
    }

    get reviewPriority() {
        return this.fieldValue(REVIEW_PRIORITY_FIELD) || 'Not assigned';
    }

    get activationBlockReasons() {
        return this.fieldValue(ACTIVATION_BLOCK_REASONS_FIELD) || 'No activation blockers supplied.';
    }

    get duplicateConfidence() {
        return this.displayValue(DUPLICATE_CONFIDENCE_FIELD) || 'Not available';
    }

    get confidenceBand() {
        return this.displayValue(CONFIDENCE_BAND_FIELD) || 'Not available';
    }

    get reviewFlagLabel() {
        return this.fieldValue(REVIEW_FLAG_FIELD) ? 'Review Required' : 'No';
    }

    get topMatchFeatures() {
        return this.fieldValue(TOP_MATCH_FEATURES_FIELD) || 'No feature payload available.';
    }

    get featureExplanations() {
        return this.fieldValue(FEATURE_EXPLANATIONS_FIELD) || 'No explanation payload available.';
    }

    get sourceSnapshotId() {
        return this.fieldValue(SOURCE_SNAPSHOT_ID_FIELD) || 'Not available';
    }

    get modelVersion() {
        return this.fieldValue(MODEL_VERSION_FIELD) || 'Not available';
    }

    get attributeValidityPayload() {
        return this.fieldValue(ATTRIBUTE_VALIDITY_PAYLOAD_FIELD) || 'No attribute trust payload available.';
    }

    get hierarchyConflictLabel() {
        return this.fieldValue(HIERARCHY_CONFLICT_FIELD) ? 'Conflict Present' : 'No Conflict';
    }

    get hierarchyImpactSummary() {
        return this.fieldValue(HIERARCHY_IMPACT_FIELD) || 'No hierarchy impact summary available.';
    }

    get hasExternalEvidence() {
        return this.leftExternalEvidence.hasEvidence || this.rightExternalEvidence.hasEvidence;
    }

    get leftExternalEvidence() {
        return this.externalEvidence(this.leftAccountRecord, this.leftAccountName);
    }

    get rightExternalEvidence() {
        return this.externalEvidence(this.rightAccountRecord, this.rightAccountName);
    }

    get registryMatchStatus() {
        const leftEvidence = this.leftExternalEvidence;
        const rightEvidence = this.rightExternalEvidence;
        if (!leftEvidence.hasEvidence || !rightEvidence.hasEvidence) {
            return 'Not enough public evidence to confirm a shared entity yet.';
        }
        if (leftEvidence.registration && rightEvidence.registration && leftEvidence.registration === rightEvidence.registration) {
            return 'Shared registration or filing reference detected.';
        }
        if (leftEvidence.legalName && rightEvidence.legalName && leftEvidence.legalName === rightEvidence.legalName) {
            return 'Matching external legal names detected.';
        }
        return 'External evidence differs across the two records.';
    }

    fieldValue(fieldRef) {
        return this.record ? getFieldValue(this.record, fieldRef) : null;
    }

    displayValue(fieldRef) {
        if (!this.record) {
            return null;
        }
        return getFieldDisplayValue(this.record, fieldRef) || getFieldValue(this.record, fieldRef);
    }

    lookupAccountLabel(accountRecord, fallbackId) {
        const label = accountRecord?.data ? getFieldValue(accountRecord.data, ACCOUNT_NAME_FIELD) : null;
        return label || fallbackId || 'Not available';
    }

    accountFieldValue(accountRecord, fieldRef) {
        return accountRecord?.data ? getFieldValue(accountRecord.data, fieldRef) : null;
    }

    externalEvidence(accountRecord, fallbackName) {
        const legalName = this.accountFieldValue(accountRecord, ACCOUNT_EXTERNAL_LEGAL_NAME_FIELD);
        const registration = this.accountFieldValue(accountRecord, ACCOUNT_EXTERNAL_REGISTRATION_FIELD);
        const externallyValidated = this.accountFieldValue(accountRecord, ACCOUNT_EXTERNALLY_VALIDATED_FIELD);
        const validityScore = this.accountFieldValue(accountRecord, ACCOUNT_EXTERNAL_VALIDITY_SCORE_FIELD);
        const citationCount = this.accountFieldValue(accountRecord, ACCOUNT_AI_CITATION_COUNT_FIELD);
        const modelId = this.accountFieldValue(accountRecord, ACCOUNT_AI_MODEL_ID_FIELD);

        return {
            accountName: fallbackName,
            legalName: legalName || 'Not available',
            registration: registration || 'Not available',
            externallyValidated: externallyValidated ? 'Validated' : 'Not validated',
            validityScore: validityScore || 'Not available',
            citationCount: citationCount || 0,
            modelId: modelId || 'Not available',
            hasEvidence: Boolean(legalName || registration || validityScore || citationCount || externallyValidated)
        };
    }

    recordUrl(recordId) {
        return recordId ? `/lightning/r/${recordId}/view` : null;
    }
}
