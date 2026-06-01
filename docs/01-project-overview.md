# 01 — Project Overview

## App Concept

A mobile platform that connects food donors (restaurants, hotels, caterers, bakeries, supermarkets, event halls) with food distributors (orphanages, madrasas, mosques, community kitchens, NGOs, shelters) to redistribute surplus food and reduce wastage.

## Problem Statement

Bangladesh generates significant food waste daily from restaurants, hotels, caterers, and events, while many organizations struggle to source food for the people they serve. There is no streamlined way to connect surplus supply with demand in real time.

## Solution

A free Android app where:

- **Donors** post surplus food with details (type, quantity, photo, pickup deadline)
- **Distributors** discover nearby available food on a map
- **Distributors** claim food and arrange pickup
- **Donors** confirm/reject claims
- **Pickup** is tracked from claim to completion

## Target Audience

| Side | Who | Motivation |
|------|-----|------------|
| **Donors** | Restaurants, hotels, caterers, bakeries, supermarkets, event halls, wedding venues | CSR, waste fee reduction, goodwill, tax benefits |
| **Distributors** | Orphanages, madrasas, mosques, community kitchens, NGOs, shelters, elderly homes | Mission-driven, need reliable food sources |

## Pilot Strategy

**Partner-network-first.** Onboard 1-2 known donors and 1-2 known distributors manually in a single locality. Validate the workflow end-to-end before expanding.

## MVP Scope (v1)

### Included

- Phone OTP authentication
- Role selection (donor / distributor)
- Donor profile creation (business name, type, address, operating hours)
- Distributor profile creation (org name, type, address, people served, pickup capability)
- Post food listing (title, category, quantity, photo, pickup deadline, address)
- Map view showing nearby available listings (GeoQuery)
- Claim food listing
- Donor confirms/rejects claim
- Distributor marks picked up
- Donor marks completed
- Push notifications on key state changes

### In progress

- In-app chat/messaging
- Bangla localization

## Core Workflow

```
DONOR posts food (status: available)
  ↓
DISTRIBUTOR discovers on map
  ↓
DISTRIBUTOR claims food (status: claimed)
  ↓
DONOR confirms (status: confirmed) / rejects (status: available again)
  ↓
DISTRIBUTOR picks up (status: picked_up)
  ↓
DONOR marks complete (status: completed)
```

## App Language

English version first. Bangla localization in progress.

## Platform

Android only (Flutter).

## Monetization

Free. Impact metrics can attract grants, CSR partnerships, and NGO funding later.
