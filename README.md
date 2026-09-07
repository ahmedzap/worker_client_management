# 📱 معمل قمة الاناقة - نظام إدارة العمال والعملاء

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![SQLite](https://img.shields.io/badge/SQLite-3.0+-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## 📋 نظرة عامة

**معمل قمة الاناقة** هو تطبيق متكامل لإدارة العمال والعملاء، مصمم خصيصاً لتلبية احتياجات المصانع والمعامل. يوفر التطبيق واجهة سهلة الاستخدام لإدارة العمليات اليومية مثل تتبع الإنتاج، المصروفات، الفواتير، وكشوف الحساب.

## ✨ الميزات الرئيسية

### 🧑‍🏭 إدارة العمال
- ➕ إضافة عامل مع رصيد افتتاحي
- 📊 تسجيل حركات الإنتاج
- 💰 تسجيل المصروفات
- 📈 تقارير أسبوعية وشهرية
- 🖨️ طباعة كشوف الحساب

### 👤 إدارة العملاء
- ➕ إضافة عميل مع رصيد افتتاحي
- 📄 فواتير توريد وشراء (متعددة الأصناف)
- 💳 سندات قبض وصرف
- 📊 كشف حساب شامل مع فلترة التاريخ
- 🖨️ طباعة كشوف الحساب

### ⚙️ الإعدادات
- 💱 إدارة العملات (ريال يمني، ريال سعودي)
- 📦 إدارة المنتجات مع أسعار البيع والإنتاج
- 🔄 تغيير العملة الافتراضية

### 🌟 ميزات إضافية
- 💱 دعم تعدد العملات
- 📱 واجهة عربية بالكامل
- 🖨️ طباعة PDF مع دعم اللغة العربية
- 📊 تقارير تفصيلية
- 💾 تخزين محلي باستخدام SQLite

## 📸 صور التطبيق

### شاشة البداية
![شاشة البداية](screenshots/splash_screen.png)

### الشاشة الرئيسية
![الشاشة الرئيسية](screenshots/home_screen.png)

### إدارة العمال
![إدارة العمال](screenshots/workers_screen.png)

### تفاصيل العامل
![تفاصيل العامل](screenshots/worker_details.png)

### إدارة العملاء
![إدارة العملاء](screenshots/clients_screen.png)

### تفاصيل العميل
![تفاصيل العميل](screenshots/client_details.png)

### كشف حساب العميل
![كشف حساب العميل](screenshots/client_statement.png)

### كشف حساب العامل
![كشف حساب العامل](screenshots/worker_statement.png)

### الإعدادات
![الإعدادات](screenshots/settings_screen.png)

### إضافة فاتورة
![إضافة فاتورة](screenshots/add_invoice.png)

### طباعة PDF
![طباعة PDF](screenshots/pdf_print.png)

## 🚀 كيفية تشغيل التطبيق

### المتطلبات الأساسية
- Flutter SDK 3.0+
- Android Studio / VS Code
- Android SDK (للتشغيل على Android)
- Xcode (للتشغيل على iOS)

### خطوات التشغيل

1. **نسخ المشروع**
```bash
git clone https://github.com/yourusername/worker_client_management.git
cd worker_client_management
