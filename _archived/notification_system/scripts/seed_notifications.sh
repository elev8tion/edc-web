#!/bin/bash
# Seed notification data to NoCodeBackend
# Usage: ./seed_notifications.sh YOUR_API_KEY

API_KEY=${1:-"YOUR_API_KEY"}
INSTANCE="36905_activation_codes"
BASE_URL="https://openapi.nocodebackend.com"

# Get today's day of year
DAY_OF_YEAR=$(date +%j | sed 's/^0*//')

echo "Seeding notification data for day $DAY_OF_YEAR..."

# Seed a verse for today
echo "Adding verse..."
curl -s -X POST "${BASE_URL}/create/notification_verses" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"Instance\": \"${INSTANCE}\",
    \"day_of_year\": ${DAY_OF_YEAR},
    \"reference\": \"Philippians 4:13\",
    \"text\": \"I can do all things through Christ who strengthens me.\",
    \"translation\": \"WEB\"
  }"
echo ""

# Seed a devotional for today
echo "Adding devotional..."
curl -s -X POST "${BASE_URL}/create/notification_devotionals" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"Instance\": \"${INSTANCE}\",
    \"day_of_year\": ${DAY_OF_YEAR},
    \"title\": \"Strength in Christ\",
    \"opening_scripture\": \"When we feel weak, God's strength is made perfect.\",
    \"key_verse\": \"Philippians 4:13\"
  }"
echo ""

# Seed a reading plan for today
echo "Adding reading plan..."
curl -s -X POST "${BASE_URL}/create/notification_reading_plans" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"Instance\": \"${INSTANCE}\",
    \"day_of_year\": ${DAY_OF_YEAR},
    \"book\": \"Genesis\",
    \"chapters\": \"1-3\"
  }"
echo ""

echo "Done! Seeded data for day ${DAY_OF_YEAR}"
