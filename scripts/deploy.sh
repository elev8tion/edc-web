#!/bin/bash
# =============================================================================
# Everyday Christian - Production Deployment Script
# =============================================================================
# This is the ONLY way to deploy to Netlify production.
# Do NOT modify or use alternative deployment methods.
# =============================================================================

# THE ONLY DEPLOY COMMAND - DO NOT CHANGE:
netlify deploy --prod --dir=build/web 2>&1
