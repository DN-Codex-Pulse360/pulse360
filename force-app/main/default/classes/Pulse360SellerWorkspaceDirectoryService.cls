public with sharing class Pulse360SellerWorkspaceDirectoryService {
    public class PreviewAccount {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String primaryBrandName;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public Decimal hiddenRevenue;
        @AuraEnabled public Boolean coverageGapFlag;
        @AuraEnabled public Decimal crossSellPropensity;
        @AuraEnabled public Decimal healthScore;
        @AuraEnabled public String freshnessLabel;
    }

    @AuraEnabled(cacheable=true)
    public static List<PreviewAccount> getPreviewAccounts(Integer requestedLimit) {
        Integer previewLimit = normalizeLimit(requestedLimit);
        List<PreviewAccount> previewAccounts = new List<PreviewAccount>();

        for (Account accountRecord : [
            SELECT
                Id,
                Name,
                BillingCountry,
                Primary_Brand_Name__c,
                Group_Revenue_Rollup__c,
                Group_Revenue_Visible__c,
                Coverage_Gap_Flag__c,
                Cross_Sell_Propensity__c,
                Health_Score__c,
                DataCloud_Last_Synced__c,
                AI_Narrative_Generated__c
            FROM Account
            WHERE
                Group_Revenue_Rollup__c != null
                OR Coverage_Gap_Flag__c = true
                OR Cross_Sell_Propensity__c != null
                OR AI_Narrative_Generated__c != null
            ORDER BY Group_Revenue_Rollup__c DESC NULLS LAST, LastModifiedDate DESC
            LIMIT :previewLimit
        ]) {
            PreviewAccount preview = new PreviewAccount();
            preview.accountId = accountRecord.Id;
            preview.accountName = accountRecord.Name;
            preview.primaryBrandName = accountRecord.Primary_Brand_Name__c;
            preview.currencyCode = currencyCodeForCountry(accountRecord.BillingCountry);
            preview.hiddenRevenue = hiddenRevenue(accountRecord.Group_Revenue_Rollup__c, accountRecord.Group_Revenue_Visible__c);
            preview.coverageGapFlag = accountRecord.Coverage_Gap_Flag__c == true;
            preview.crossSellPropensity = safeDecimal(accountRecord.Cross_Sell_Propensity__c);
            preview.healthScore = safeDecimal(accountRecord.Health_Score__c);
            preview.freshnessLabel = freshnessLabel(accountRecord.DataCloud_Last_Synced__c, accountRecord.AI_Narrative_Generated__c);
            previewAccounts.add(preview);
        }

        return previewAccounts;
    }

    private static Integer normalizeLimit(Integer requestedLimit) {
        if (requestedLimit == null || requestedLimit < 5) {
            return 12;
        }
        return Math.min(requestedLimit, 20);
    }

    private static Decimal safeDecimal(Decimal value) {
        return value == null ? 0 : value;
    }

    private static Decimal hiddenRevenue(Decimal totalRevenue, Decimal visibleRevenue) {
        Decimal safeTotal = safeDecimal(totalRevenue);
        Decimal safeVisible = safeDecimal(visibleRevenue);
        Decimal hidden = safeTotal - safeVisible;
        return hidden > 0 ? hidden : 0;
    }

    private static String currencyCodeForCountry(String billingCountry) {
        if (String.isBlank(billingCountry)) {
            return 'USD';
        }

        String normalized = billingCountry.toLowerCase();
        if (normalized.contains('singapore')) {
            return 'SGD';
        }
        if (normalized.contains('philippines')) {
            return 'PHP';
        }
        return 'USD';
    }

    private static String freshnessLabel(Datetime lastSyncedTimestamp, Datetime aiNarrativeGeneratedAt) {
        Integer syncDays = daysSince(lastSyncedTimestamp);
        Integer narrativeDays = daysSince(aiNarrativeGeneratedAt);
        Integer comparisonDays = minPositive(syncDays, narrativeDays);

        if (comparisonDays == null) {
            return 'Freshness unknown';
        }
        if (comparisonDays <= 7) {
            return 'Fresh';
        }
        if (comparisonDays <= 30) {
            return 'Monitor freshness';
        }
        return 'Refresh recommended';
    }

    private static Integer minPositive(Integer leftValue, Integer rightValue) {
        if (leftValue == null) {
            return rightValue;
        }
        if (rightValue == null) {
            return leftValue;
        }
        return Math.min(leftValue, rightValue);
    }

    private static Integer daysSince(Datetime value) {
        if (value == null) {
            return null;
        }
        Integer dayDelta = value.dateGmt().daysBetween(Date.today());
        return dayDelta < 0 ? 0 : dayDelta;
    }
}
