# Apple Search Ads Attribution Blocking Gap

Created: 2026-06-25

## Problem

Yearlit needs to connect Apple Search Ads installs to onboarding, paywall, trial, and paid conversion. The app can eventually request an AdServices attribution token, but that token is not useful analytics data by itself and must not be sent to PostHog or RevenueCat as a raw identifier.

## Missing Dependency

Add a server-side attribution resolver that:

- accepts an AdServices attribution token from the app over TLS
- calls Apple's attribution API from trusted infrastructure
- maps the response to coarse, non-sensitive fields
- returns only the fields the app is allowed to attach to analytics and RevenueCat subscriber attributes

Minimum returned fields:

- `acquisition_source`
- `asa_attribution_available`
- `asa_campaign_id`
- `asa_campaign_name`
- `asa_adgroup_id`
- `asa_keyword_id`
- `asa_country`
- `asa_match_type`

Only include `asa_keyword_text` if the resolver guarantees it comes from Apple Search Ads metadata and is not user-generated content.

## App Implementation After Resolver Exists

Once the resolver endpoint exists, the app should:

- request the AdServices token once after launch or onboarding start
- send the token to the resolver, not directly to PostHog or RevenueCat
- set PostHog person properties from the resolver response
- add coarse acquisition properties to key onboarding, paywall, and purchase events
- set matching RevenueCat subscriber attributes for source, campaign, ad group, keyword, country, and match type
- persist the resolved attribution locally so later purchase events include the same acquisition fields

## Current Status

Blocked. There is no resolver endpoint or existing ASA attribution service in this codebase, and client-only token capture would create an unusable half-solution.
