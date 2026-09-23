# Akira Flow — Leaflet & print ads

## Folders

| Path | Contents |
|------|----------|
| `leaflets/*.png` | **A5 print** — one flyer per business type (with Play QR + support) |
| `leaflets/square/` | **1:1** WhatsApp / IG / FB ads (22) |
| `leaflets/story/` | **9:16** Status / Reels / Stories (22) |
| `leaflets/qr-play-store.png` | Standalone QR → Play listing (`app.akirabizhub.pos`) |

## General brand creatives (this folder)

| File | Orientation | Best use |
|------|-------------|-------------------------|
| `akira-flow-leaflet-a5.png` | Portrait | Generic A5 |
| `akira-flow-leaflet-a5-screens-mama.png` | Portrait | A5 with app UI + mama mboga |
| `akira-flow-ad-square.png` | Square | Social — text version |
| `akira-flow-ad-square-screens-mama.png` | Square | Social — screens |
| `akira-flow-story-ad.png` | Tall | Status — text version |
| `akira-flow-story-screens-mama.png` | Tall | Status — screens |

## Per-business files (`leaflets/`)

| Business | A5 | Square | Story |
|----------|----|--------|-------|
| Food Vendors | `leaflet-food-vendor-a5.png` | `square/leaflet-food-vendor-square.png` | `story/leaflet-food-vendor-story.png` |
| Small Restaurant | `leaflet-small-restaurant-a5.png` | `square/…` | `story/…` |
| Pharmacies | `leaflet-pharmacy-a5.png` | `square/…` | `story/…` |
| General Retail Kiosk | `leaflet-grocery-shop-a5.png` | `square/…` | `story/…` |
| Fresh Foods (Mama Mboga) | `leaflet-mama-mboga-a5.png` | `square/…` | `story/…` |
| Milk Bar / Dairy | `leaflet-dairy-shop-a5.png` | `square/…` | `story/…` |
| Poultry & Egg Supply | `leaflet-poultry-shop-a5.png` | `square/…` | `story/…` |
| Wholesale Store | `leaflet-wholesale-a5.png` | `square/…` | `story/…` |
| Wines & Spirits | `leaflet-liquor-store-a5.png` | `square/…` | `story/…` |
| Gas & Water Refill | `leaflet-gas-water-a5.png` | `square/…` | `story/…` |
| Clothing Boutique | `leaflet-boutique-a5.png` | `square/…` | `story/…` |
| Shoe Store | `leaflet-shoe-store-a5.png` | `square/…` | `story/…` |
| Hardware Store | `leaflet-hardware-store-a5.png` | `square/…` | `story/…` |
| Agrovets | `leaflet-agrovet-a5.png` | `square/…` | `story/…` |
| Electronic Shop | `leaflet-electronics-shop-a5.png` | `square/…` | `story/…` |
| Cyber Cafe | `leaflet-cybercafe-a5.png` | `square/…` | `story/…` |
| Salon / Kinyozi | `leaflet-salon-a5.png` | `square/…` | `story/…` |
| Cosmetics Shop | `leaflet-beauty-shop-a5.png` | `square/…` | `story/…` |
| Butchery | `leaflet-butchery-a5.png` | `square/…` | `story/…` |
| Baby Shop | `leaflet-baby-shop-a5.png` | `square/…` | `story/…` |
| Bakery | `leaflet-bakery-a5.png` | `square/…` | `story/…` |
| Phone Repair | `leaflet-phone-repair-a5.png` | `square/…` | `story/…` |

Naming pattern: `leaflet-<business_id>-{a5|square|story}.png` matching app IDs in `lib/core/business_type_config.dart`.

## Contact strip (on every per-business creative)

Already composited on each file:

- **QR** → `https://play.google.com/store/apps/details?id=app.akirabizhub.pos`
- **Search:** Akira Flow  
- **Email:** susanmwangi968@gmail.com  
- WhatsApp number was not in the repo — footer says to ask via Play / email. Send your **WhatsApp business number** and we can stamp it on all 66 files.

## Print tips

1. Open the A5 PNG in Google Docs / Canva / LibreOffice → page **A5**.  
2. Print on **matt 150–200 gsm** if possible.  
3. Hand out the **matching business leaflet** when pitching that shop type.  
4. Share **square** in WhatsApp groups; **story** on Status / Reels.

## Suggested back-of-leaflet copy

```
Akira Flow
POS for Kenyan shops

• Cash & M-Pesa sales
• Stock & expenses
• Daily profit on your phone
• Email or Google sign-in

Get it free on Google Play
Search: Akira Flow
Scan the QR on the front

Support: susanmwangi968@gmail.com
```

## Where to distribute

- Market stalls / agent desks  
- Cybercafé notice boards  
- WhatsApp broadcast lists (use `leaflets/square/`)  
- Status / Reels (use `leaflets/story/`)  
- Shopkeeper Facebook/WhatsApp groups  
- Trade associations (pharmacy, hardware, salon groups)
