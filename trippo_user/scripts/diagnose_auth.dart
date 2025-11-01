#!/usr/bin/env dart

/// Script to diagnose Firebase authentication and Firestore user data issues
/// Run with: dart run scripts/diagnose_auth.dart <email>

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: dart run scripts/diagnose_auth.dart <email>');
    exit(1);
  }

  final email = args[0];
  print('🔍 Diagnosing authentication for: $email\n');

  try {
    // Initialize Firebase (you'll need to provide project credentials)
    print('📱 Initializing Firebase...');
    
    // Note: This requires manual Firebase initialization
    // For now, we'll create a simple Node.js version instead
    print('⚠️  Please use the Node.js version: node scripts/diagnose_auth.js $email');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

