## Getting your secure score from the REST API

The Azure Secure score is a key aspect of the Azure Security Center, it has two main goals: to help you understand your current security situation, and to help you efficiently and effectively improve your security.

Azure Security Center continually checks your subscriptions and resources for security issues and vulnerabilities. It then aggregates all the results into a single score so that you can use to to determine your current security situation: the higher the score, the lower the identified risk level.

By using these samples you can get your Azure Secure Score for a subscription by calling the Azure Security Center REST API. The API methods provide the flexibility to query the data and build your own reporting mechanism of your secure scores over time.

An azure security control is a logical group of security recommendations, with instructions that help you implement those recommendations. Your score only improves when you remediate all of the recommendations for a single resource within a control. To immediately see how well your organization is securing each individual attack surface, review the scores for each individual security control.

### Powershell commands

Run the powershell script AzureSecureScore.ps1 get the score for a specific subscription.

```powershell
.\AzureSecureScore.ps1 -TenantId [TenantId] -ClientId [ClientId] -ClientSecret [ClientSecret] -Resource https://management.core.windows.net/ -SubscriptionId [subscriptionId]
```

The output of this script is a json file named AzureSecureScore.json

```Json
{
  "value": [
    {
      "id": "/subscriptions/{subscriptionId}/providers/Microsoft.Security/secureScores/ascScore",
      "name": "ascScore",
      "type": "Microsoft.Security/secureScores",
      "properties": {
        "displayName": "ASC score",
        "score": {
          "max": 55,
          "current": 37.0
        }
      }
    }
  ]
}
```

Run the powershell script AzureSecureScoreControls.ps1 to list the security controls and the current score of your subscriptions.

```powershell
.\AzureSecureScoreControls.ps1 -TenantId [TenantId] -ClientId [ClientId] -ClientSecret [ClientSecret] -Resource https://management.core.windows.net/ -SubscriptionId [subscriptionId]
```

The output of this script is a json file named AzureSecureScoreControls.ps1

```Json
{
  "value": [
    {
      "id": "/subscriptions/{subscriptionId}/providers/Microsoft.Security/secureScoreControls/a9909064-42b4-4d34-8143-275477afe18b",
      "name": "a9909064-42b4-4d34-8143-275477afe18b",
      "type": "Microsoft.Security/secureScoreControls",
      "properties": {
        "displayName": "Protect applications against DDoS attacks",
        "score": {
          "max": 2,
          "current": 0.0
        },
        "healthyResourceCount": 0,
        "unhealthyResourceCount": 0,
        "notApplicableResourceCount": 1
      }
    },
    {
      "..."
    }
  ]
}
```

As you can see it includes a list of security controls with a corresponding score. To get all the possible points for a security control and maximize the score, all your resources must comply with all of the security recommendations included in the security control. For example, Security Center has multiple recommendations regarding how to secure your management ports. In the past, you could remediate some of those related and interdependent recommendations while leaving others unsolved. Now, you must remediate them all to make a difference to your secure score.

To learn more about Azure Secure Score, Score controls and recommendations, see [this article](https://docs.microsoft.com/azure/security-center/secure-score-security-controls).

Also, see [this GitHub repo](https://github.com/Azure/Azure-Security-Center/tree/master/Remediation%20scripts) which contains several samples to help you programmatic remediate your Security Center recommendations, and thus improving your Secure score.