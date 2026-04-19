/// ─── Canteen Localization — Phase 9 ─────────────────────────────────────────
///
/// Single source of truth for ALL user-facing strings on the canteen side.
/// Three languages: English (en), Hindi (hi), Marathi (mr).
///
/// Rules:
///  - DO NOT translate internal enums, API values, route names, or logic keys.
///  - Translations are natural / staff-friendly, NOT word-for-word literal.
///  - Token numbers, prices, timestamps, and IDs are runtime values and are
///    NOT translated here — they come from the backend.
///  - Emoji characters are kept as-is across all languages.
///
/// Usage:
///   final s = ref.watch(canteenL10nProvider);
///   Text(s.orders);          // → 'Orders' / 'ऑर्डर' / 'ऑर्डर'
///   Text(s.verifyAndCollect); // …

library;

class CanteenStrings {
  final String languageCode;
  const CanteenStrings._(this.languageCode);

  static const en = CanteenStrings._('en');
  static const hi = CanteenStrings._('hi');
  static const mr = CanteenStrings._('mr');

  static CanteenStrings fromCode(String code) {
    switch (code) {
      case 'hi': return hi;
      case 'mr': return mr;
      default:   return en;
    }
  }

  // ── Language meta ──────────────────────────────────────────────────────────

  String get languageName => _s(en: 'English', hi: 'हिन्दी', mr: 'मराठी');
  String get selectLanguage => _s(en: 'Language', hi: 'भाषा', mr: 'भाषा');

  // ── Shell / Bottom Nav ────────────────────────────────────────────────────

  String get navVerify  => _s(en: 'Verify',  hi: 'वेरिफाय', mr: 'तपासा');
  String get navOrders  => _s(en: 'Orders',  hi: 'ऑर्डर',   mr: 'ऑर्डर');
  String get navMenu    => _s(en: 'Menu',    hi: 'मेन्यू',   mr: 'मेन्यू');
  String get navReports => _s(en: 'Reports', hi: 'रिपोर्ट',  mr: 'अहवाल');
  String get navProfile => _s(en: 'Profile', hi: 'प्रोफाइल', mr: 'प्रोफाइल');

  // ── Orders Screen ─────────────────────────────────────────────────────────

  String get kitchenOrders    => _s(en: 'Kitchen Orders',    hi: 'किचन ऑर्डर',       mr: 'स्वयंपाकघर ऑर्डर');
  String get campusEatsCanteen => _s(en: 'CampusEats Canteen', hi: 'कँपसईट्स कँटीन', mr: 'कँपसईट्स कँटीन');
  String get search           => _s(en: 'Search token, name, or item…', hi: 'टोकन, नाव किंवा आयटम शोधा…', mr: 'टोकन, नाव किंवा वस्तू शोधा…');
  String get switchToDark     => _s(en: 'Switch to Dark Mode',  hi: 'डार्क मोड करा',  mr: 'डार्क मोड करा');
  String get switchToLight    => _s(en: 'Switch to Light Mode', hi: 'लाइट मोड करा',   mr: 'लाइट मोड करा');
  String get helpAndContact   => _s(en: 'Help & Contact',       hi: 'मदत व संपर्क',    mr: 'मदत व संपर्क');
  String get refreshOrders    => _s(en: 'Refresh orders',       hi: 'ऑर्डर रिफ्रेश करा', mr: 'ऑर्डर ताजे करा');

  // ── Phase 10: New Order Banner ─────────────────────────────────────────────

  String get newOrderBannerSingle => _s(
    en: '⚡ 1 new order arrived — queue updated!',
    hi: '⚡ 1 नवा ऑर्डर आला — रांग अपडेट झाली!',
    mr: '⚡ 1 नवीन ऑर्डर आला — रांग अपडेट झाली!',
  );
  String newOrderBannerMultiple(int n) => _s(
    en: '⚡ $n new orders arrived — queue updated!',
    hi: '⚡ $n नवे ऑर्डर आले — रांग अपडेट झाली!',
    mr: '⚡ $n नवीन ऑर्डर आले — रांग अपडेट झाली!',
  );

  // ── Tabs ──────────────────────────────────────────────────────────────────

  String get tabQueue     => _s(en: 'Queue',     hi: 'प्रतीक्षा',   mr: 'रांग');
  String get tabPrinted   => _s(en: 'Printed',   hi: 'प्रिंट केले', mr: 'छापले');
  String get tabCompleted => _s(en: 'Completed',  hi: 'पूर्ण',       mr: 'पूर्ण');

  // ── Order Card ────────────────────────────────────────────────────────────

  String get paid         => _s(en: 'PAID',      hi: 'भरले',     mr: 'भरले');
  String get openSlip     => _s(en: 'Open Slip', hi: 'स्लिप पाहा', mr: 'स्लिप उघडा');
  String get faculty      => _s(en: 'FACULTY',   hi: 'फॅकल्टी',   mr: 'शिक्षक');
  String get student      => _s(en: 'Student',   hi: 'विद्यार्थी', mr: 'विद्यार्थी');

  // State chips on card
  String get chipPrinted   => _s(en: 'PRINTED',   hi: 'प्रिंट',   mr: 'छापले');
  String get chipDone      => _s(en: 'DONE',       hi: 'पूर्ण',    mr: 'पूर्ण');
  String get chipScheduled => _s(en: 'SCHEDULED',  hi: 'शेड्युल्ड', mr: 'वेळ ठरला');

  // Prepare Now section label
  String get prepareNow   => _s(en: 'Prepare Now', hi: 'आत्ता बनवा', mr: 'आत्ता तयार करा');

  // Order count suffix
  String orderCount(int n) => n == 1
      ? _s(en: '1 order', hi: '1 ऑर्डर', mr: '1 ऑर्डर')
      : _s(en: '$n orders', hi: '$n ऑर्डर', mr: '$n ऑर्डर');

  // Pickup time label
  String pickupAt(String time) => _s(
    en: 'Pickup at $time',
    hi: 'पिकअप: $time',
    mr: 'वेळ: $time',
  );

  // ── Phase 11: Mark Ready ─────────────────────────────────────────────────

  String get markReady   => _s(en: '🔔 Mark Ready', hi: '🔔 तयार करा',        mr: '🔔 तयार आहे');
  String get markedReady => _s(en: '✓ Customer notified — order is ready!',
                                hi: '✓ ग्राहकाला सूचना दिली — ऑर्डर तयार आहे!',
                                mr: '✓ ग्राहकाला सूचना दिली — ऑर्डर तयार आहे!');
  String get orderReady  => _s(en: '✓ READY',       hi: '✓ तयार',     mr: '✓ तयार');
  String get failedMsg   => _s(en: 'Action failed', hi: 'कृती अयशस्वी', mr: 'क्रिया अयशस्वी');

  // ── Phase 11: Thermal Printer ─────────────────────────────────────────────

  String get thermalPrinterTitle    => _s(en: 'Thermal Printer',         hi: 'थर्मल प्रिंटर',       mr: 'थर्मल प्रिंटर');
  String get thermalConnected       => _s(en: '🖨 Printer connected',     hi: '🖨 प्रिंटर जोडले',     mr: '🖨 प्रिंटर जोडले');
  String get thermalDisconnected    => _s(en: 'No thermal printer set',   hi: 'थर्मल प्रिंटर नाही',  mr: 'थर्मल प्रिंटर नाही');
  String get thermalPrinting        => _s(en: 'Printing…',                hi: 'प्रिंट होत आहे…',     mr: 'प्रिंट होत आहे…');
  String get thermalNotFound        => _s(en: 'Printer not reachable. Using fallback.',
                                          hi: 'प्रिंटर उपलब्ध नाही. दुसरा मार्ग वापरत आहे.',
                                          mr: 'प्रिंटर उपलब्ध नाही. पर्याय वापरत आहे.');
  String get thermalUseFallback     => _s(en: '⚠ Use System Print Instead',
                                          hi: '⚠ सिस्टम प्रिंट वापरा',
                                          mr: '⚠ सिस्टम प्रिंट वापरा');
  String get directPrint            => _s(en: '🖨 Direct Thermal Print',  hi: '🖨 थेट प्रिंट',        mr: '🖨 थेट प्रिंट');
  String get fallbackPrint          => _s(en: '📄 System / PDF Print',    hi: '📄 सिस्टम प्रिंट',    mr: '📄 सिस्टम प्रिंट');
  String get pairPrinter            => _s(en: 'Scan & Pair Printer',      hi: 'प्रिंटर जोडा',        mr: 'प्रिंटर जोडा');
  String get clearPrinter           => _s(en: 'Remove Paired Printer',    hi: 'प्रिंटर काढा',        mr: 'प्रिंटर काढा');
  String get printerPairedAs        => _s(en: 'Paired printer:',          hi: 'जोडलेला प्रिंटर:',    mr: 'जोडलेला प्रिंटर:');
  String get printDirect            => _s(en: '✓ Printed directly to thermal printer',
                                          hi: '✓ थर्मल प्रिंटरवर थेट प्रिंट केले',
                                          mr: '✓ थर्मल प्रिंटरवर थेट प्रिंट केले');
  String get printFallbackSuccess   => _s(en: '✓ Marked as printed (system print dialog)',
                                          hi: '✓ प्रिंट केले (सिस्टम डायलॉग)',
                                          mr: '✓ प्रिंट केले (सिस्टम डायलॉग)');
  String get printBackendFailed     => _s(en: 'Could not mark order as printed',
                                          hi: 'ऑर्डर प्रिंट म्हणून मार्क करता आले नाही',
                                          mr: 'ऑर्डर प्रिंट म्हणून मार्क करता आले नाही');

  // ── Empty States ──────────────────────────────────────────────────────────

  String get emptyQueue     => _s(en: 'Queue is clear!',       hi: 'रांग रिकामी आहे!',      mr: 'रांग रिकामी आहे!');
  String get emptyQueueSub  => _s(en: 'New paid orders appear here — pull to refresh',
                                  hi: 'नवे ऑर्डर इथे दिसतील — खाली ओढा',
                                  mr: 'नवीन ऑर्डर इथे दिसतील — खाली ओढा');
  String get emptyPrinted    => _s(en: 'No printed orders',    hi: 'काहीच प्रिंट नाही',      mr: 'कोणतेही छापलेले नाही');
  String get emptyPrintedSub => _s(en: 'When you print a slip, the order moves here',
                                   hi: 'स्लिप प्रिंट केल्यावर ऑर्डर इथे येतो',
                                   mr: 'स्लिप छापल्यावर ऑर्डर इथे येतो');
  String get emptyCompleted    => _s(en: 'No completed orders',     hi: 'कोणताही पूर्ण ऑर्डर नाही', mr: 'कोणताही पूर्ण ऑर्डर नाही');
  String get emptyCompletedSub => _s(en: 'Verified and collected orders appear here',
                                     hi: 'वेरिफाय झालेले ऑर्डर इथे दिसतात',
                                     mr: 'तपासलेले व घेतलेले ऑर्डर इथे दिसतात');

  // ── Loading States ────────────────────────────────────────────────────────

  String get loadingOrders   => _s(en: 'Loading orders…',      hi: 'ऑर्डर लोड होत आहे…',   mr: 'ऑर्डर लोड होत आहे…');
  String get verifyingOrder  => _s(en: 'Verifying order…',     hi: 'ऑर्डर तपासत आहे…',    mr: 'ऑर्डर तपासत आहे…');
  String get loadingMenu     => _s(en: 'Loading menu…',        hi: 'मेन्यू लोड होत आहे…',  mr: 'मेन्यू लोड होत आहे…');

  // ── Slip Bottom Sheet ─────────────────────────────────────────────────────

  String get campusEats      => _s(en: 'CAMPUS EATS',       hi: 'कँपस ईट्स',       mr: 'कँपस ईट्स');
  String get slipActive      => _s(en: 'ACTIVE',            hi: 'सक्रिय',           mr: 'सक्रिय');
  String get slipPrinted     => _s(en: 'PRINTED',           hi: 'प्रिंट',           mr: 'छापले');
  String get slipCollected   => _s(en: 'COLLECTED',         hi: 'मिळाले',           mr: 'घेतले');

  String get slipName        => _s(en: 'Name',              hi: 'नाव',              mr: 'नाव');
  String get slipRole        => _s(en: 'Role',              hi: 'भूमिका',           mr: 'भूमिका');
  String get slipRoleFaculty => _s(en: 'Faculty',           hi: 'फॅकल्टी',          mr: 'शिक्षक');
  String get slipRoleStudent => _s(en: 'Student',           hi: 'विद्यार्थी',        mr: 'विद्यार्थी');
  String get slipDept        => _s(en: 'Department',        hi: 'विभाग',            mr: 'विभाग');
  String get slipRoom        => _s(en: 'Room / Office',     hi: 'कक्ष / ऑफिस',     mr: 'खोली / कार्यालय');
  String get slipOrdered     => _s(en: 'Ordered',           hi: 'ऑर्डर वेळ',        mr: 'ऑर्डर वेळ');
  String get slipPickupTime  => _s(en: 'Pickup Time',       hi: 'पिकअप वेळ',        mr: 'वेळ');
  String get slipReadyBy     => _s(en: 'Ready By (ETA)',    hi: 'तयार होण्याची वेळ', mr: 'तयार होण्याची वेळ');
  String get slipPayment     => _s(en: 'Payment',           hi: 'पेमेंट',           mr: 'देणगी');
  String get slipPaidLabel   => _s(en: 'PAID • UPI / Razorpay', hi: 'भरले • UPI / Razorpay', mr: 'भरले • UPI / Razorpay');
  String get slipOrderItems  => _s(en: 'ORDER ITEMS',       hi: 'ऑर्डर वस्तू',      mr: 'ऑर्डर वस्तू');
  String get slipTotal       => _s(en: 'TOTAL',             hi: 'एकूण',             mr: 'एकूण');
  // Phase 10: renamed from slipMarkPrinted → slipPrintAndMark
  String get slipPrintAndMark => _s(en: 'Print & Mark',     hi: 'प्रिंट करा व नोंद करा', mr: 'छापा व नोंद करा');
  String get slipClose       => _s(en: 'Close',             hi: 'बंद करा',           mr: 'बंद करा');

  String copyTokenLabel(String token) => _s(
    en: 'Copy Token #$token',
    hi: 'टोकन #$token कॉपी करा',
    mr: 'टोकन #$token कॉपी करा',
  );
  String tokenCopied(String token) => _s(
    en: 'Token #$token copied',
    hi: 'टोकन #$token कॉपी झाला',
    mr: 'टोकन #$token कॉपी झाला',
  );

  // ── Verify Screen ─────────────────────────────────────────────────────────

  String get verifyAndCollect    => _s(en: 'Verify & Collect',         hi: 'वेरिफाय व द्या',            mr: 'तपासा व द्या');
  String get scanQr              => _s(en: 'Scan QR',                  hi: 'QR स्कॅन करा',             mr: 'QR स्कॅन करा');
  String get enterTokenTitle     => _s(en: 'Enter Token Number',       hi: 'टोकन नंबर टाका',           mr: 'टोकन क्रमांक टाका');
  String get enterTokenSubtitle  => _s(en: 'Enter the 4-digit token shown on the student\'s QR, or scan the QR directly.',
                                       hi: 'विद्यार्थ्याच्या QR वरचा 4-अंकी टोकन टाका किंवा थेट QR स्कॅन करा.',
                                       mr: 'विद्यार्थ्याच्या QR वरील 4-अंकी टोकन टाका किंवा थेट QR स्कॅन करा.');
  String get clearBtn            => _s(en: 'Clear',   hi: 'साफ करा', mr: 'साफ करा');
  String get verifyBtn           => _s(en: 'Verify',  hi: 'तपासा',   mr: 'तपासा');

  // QR scan sheet
  String get scanStudentQr       => _s(en: 'Scan Student QR Code',     hi: 'विद्यार्थ्याचा QR स्कॅन करा', mr: 'विद्यार्थ्याचा QR स्कॅन करा');
  String get pointCameraAt       => _s(en: 'Point the camera at the student\'s order QR code',
                                       hi: 'कॅमेरा विद्यार्थ्याच्या QR कोडवर ठेवा',
                                       mr: 'कॅमेरा विद्यार्थ्याच्या QR कोडवर धरा');
  String get cameraActive        => _s(en: 'Camera active — point at the QR code', hi: 'कॅमेरा सुरू आहे — QR कडे करा', mr: 'कॅमेरा सुरू — QR कडे धरा');
  String get cancelEnterManually => _s(en: 'Cancel — enter token manually instead',
                                       hi: 'रद्द करा — टोकन हाताने टाका',
                                       mr: 'रद्द करा — टोकन स्वतः टाका');

  // Permission denied
  String get cameraAccessNeeded  => _s(en: 'Camera Access Needed',     hi: 'कॅमेरा परवानगी हवी',         mr: 'कॅमेरा परवानगी द्या');
  String get cameraDeniedMsg     => _s(
    en: 'Camera permission was denied.\n\nPlease use the token number instead:\nAsk the student for their 4-digit token and enter it manually.',
    hi: 'कॅमेरा परवानगी नाकारली गेली.\n\nटोकन नंबर वापरा:\nविद्यार्थ्याकडून 4-अंकी टोकन घ्या व हाताने टाका.',
    mr: 'कॅमेरा परवानगी नाकारली.\n\nटोकन क्रमांक वापरा:\nविद्यार्थ्याकडून 4-अंकी टोकन घेऊन स्वतः टाका.',
  );
  String get openAppSettings     => _s(en: 'Open App Settings',        hi: 'सेटिंग्ज उघडा',             mr: 'सेटिंग्ज उघडा');

  // Verify results
  String get tokenNotFound       => _s(en: 'Token Not Found',          hi: 'टोकन सापडले नाही',           mr: 'टोकन सापडले नाही');
  String get verifyError         => _s(en: 'Verification Error',       hi: 'तपासणी त्रुटी',              mr: 'तपासणीत चूक');
  String get alreadyCollected    => _s(en: 'Already Collected',        hi: 'आधीच मिळाले',                mr: 'आधीच घेतले');
  String get alreadyCollectedSub => _s(en: 'This order was already collected. No action needed.',
                                       hi: 'हा ऑर्डर आधीच दिला गेला. काहीच करायचे नाही.',
                                       mr: 'हा ऑर्डर आधीच घेतला. काही करायची गरज नाही.');
  String get paymentPending      => _s(en: 'Payment Pending',          hi: 'पेमेंट बाकी आहे',            mr: 'पेमेंट बाकी आहे');
  String get paymentPendingSub   => _s(en: 'This order has not been paid yet. Ask the student to complete payment.',
                                       hi: 'हा ऑर्डर अजून पेमेंट झाला नाही. विद्यार्थ्याला सांगा.',
                                       mr: 'या ऑर्डरचे पेमेंट झाले नाही. विद्यार्थ्याला पेमेंट करायला सांगा.');
  String get orderCancelled      => _s(en: 'Order Cancelled',          hi: 'ऑर्डर रद्द झाला',            mr: 'ऑर्डर रद्द झाला');
  String get orderCancelledSub   => _s(en: 'This order was cancelled and cannot be collected.',
                                       hi: 'हा ऑर्डर रद्द झाला आहे. देणे शक्य नाही.',
                                       mr: 'हा ऑर्डर रद्द झाला आहे. देता येणार नाही.');
  String get orderVerifiedTitle  => _s(en: '✓ Order Verified & Collected!', hi: '✓ ऑर्डर वेरिफाय व दिला!', mr: '✓ ऑर्डर तपासला व दिला!');
  String get verifyIssue         => _s(en: 'Verification Issue',       hi: 'तपासणीमध्ये अडचण',           mr: 'तपासणीत अडचण');

  // Verify result summary card labels
  String get verifyItemsLabel    => _s(en: 'Items',                    hi: 'वस्तू',                     mr: 'वस्तू');
  String get verifyTotalLabel    => _s(en: 'Total',                    hi: 'एकूण',                      mr: 'एकूण');
  String get verifyStudentLabel  => _s(en: 'Student',                  hi: 'विद्यार्थी',                 mr: 'विद्यार्थी');

  // ── Menu Management Screen ────────────────────────────────────────────────

  String get menuControls        => _s(en: 'Menu Controls',            hi: 'मेन्यू नियंत्रण',            mr: 'मेन्यू नियंत्रण');
  String get menuRefresh         => _s(en: 'Refresh',                  hi: 'ताजे करा',                  mr: 'ताजे करा');
  String get menuLegend          => _s(en: 'Toggle availability & special flags. Changes take effect immediately for students.',
                                       hi: 'उपलब्धता व स्पेशल बदलू शकता. बदल लगेच विद्यार्थ्यांना दिसतो.',
                                       mr: 'उपलब्धता व स्पेशल बदलता येतो. बदल लगेच विद्यार्थ्यांना दिसतो.');
  String get menuSearch          => _s(en: 'Find item...',             hi: 'वस्तू शोधा...',              mr: 'वस्तू शोधा...');
  String get menuNoItems         => _s(en: 'No items found',           hi: 'वस्तू सापडली नाही',          mr: 'वस्तू सापडली नाही');
  String get menuNoItemsSub      => _s(en: 'Try a different search',   hi: 'वेगळ्या शब्दाने शोधा',       mr: 'वेगळ्या शब्दाने शोधा');

  String get markUnavailable     => _s(en: 'Mark Unavailable Today',   hi: 'आज उपलब्ध नाही म्हणा',       mr: 'आज उपलब्ध नाही म्हणून नोंद करा');
  String get markAvailable       => _s(en: 'Mark Available',           hi: 'उपलब्ध म्हणा',               mr: 'उपलब्ध म्हणून नोंद करा');
  String get removeSpecial       => _s(en: 'Remove Special Flag',      hi: 'स्पेशल काढा',                mr: 'स्पेशल काढा');
  String get markAsSpecial       => _s(en: 'Mark as Special',          hi: 'स्पेशल म्हणा',               mr: 'स्पेशल म्हणून नोंद करा');
  String get unavailableToday    => _s(en: 'Unavailable Today',        hi: 'आज उपलब्ध नाही',             mr: 'आज उपलब्ध नाही');

  // Special label dialog
  String get chooseSpecialLabel  => _s(en: 'Mark as Special',         hi: 'स्पेशल म्हणून नोंद करा',      mr: 'स्पेशल म्हणून नोंद करा');
  String chooseForItem(String name) => _s(
    en: 'Choose a label for "$name"',
    hi: '"$name" के लिए लेबल चुनें',
    mr: '"$name" साठी लेबल निवडा',
  );
  String get orTypeCustomLabel   => _s(en: 'Or type custom label',    hi: 'किंवा खुद का लेबल टाइप करें', mr: 'किंवा स्वतःचा लेबल टाका');
  String get cancel              => _s(en: 'Cancel',                  hi: 'रद्द करें',                   mr: 'रद्द करा');
  String get markSpecialBtn      => _s(en: 'Mark Special',            hi: 'स्पेशल करें',                  mr: 'स्पेशल करा');

  // Snackbars from menu management
  String markedUnavailable(String name) => _s(
    en: '$name marked unavailable today',
    hi: '$name आज उपलब्ध नाही',
    mr: '$name आज उपलब्ध नाही',
  );
  String markedAvailableAgain(String name) => _s(
    en: '$name is available again',
    hi: '$name पुन्हा उपलब्ध आहे',
    mr: '$name पुन्हा उपलब्ध आहे',
  );
  String markedSpecial(String name, String label) => _s(
    en: '$name marked as "$label"',
    hi: '$name "$label" म्हणून नोंदवले',
    mr: '$name "$label" म्हणून नोंद केले',
  );
  String specialRemoved(String name) => _s(
    en: 'Special flag removed from $name',
    hi: '$name चे स्पेशल काढले',
    mr: '$name चे स्पेशल काढले',
  );
  String get failedPrefix => _s(en: 'Failed', hi: 'त्रुटी', mr: 'त्रुटी');

  // ── Profile Screen ────────────────────────────────────────────────────────

  String get staffProfile        => _s(en: 'Staff Profile',             hi: 'स्टाफ प्रोफाइल',            mr: 'स्टाफ प्रोफाइल');
  String get canteenStaff        => _s(en: 'Canteen Staff',             hi: 'कँटीन स्टाफ',               mr: 'कँटीन स्टाफ');
  String get sectionStaffInfo    => _s(en: 'Staff Info',                hi: 'स्टाफ माहिती',               mr: 'स्टाफ माहिती');
  String get labelFullName       => _s(en: 'Full Name',                 hi: 'पूर्ण नाव',                  mr: 'पूर्ण नाव');
  String get labelPhone          => _s(en: 'Phone',                     hi: 'फोन',                       mr: 'फोन');
  String get labelCanteen        => _s(en: 'Canteen',                   hi: 'कँटीन',                     mr: 'कँटीन');
  String get labelRole           => _s(en: 'Role',                      hi: 'भूमिका',                    mr: 'भूमिका');
  String get labelShiftTiming    => _s(en: 'Shift Timing',              hi: 'ड्युटी वेळ',                 mr: 'ड्युटी वेळ');

  String get sectionAppearance   => _s(en: 'Appearance',                hi: 'देखावा',                    mr: 'देखावा');
  String get darkMode            => _s(en: 'Dark Mode',                 hi: 'डार्क मोड',                 mr: 'डार्क मोड');
  String get darkModeActive      => _s(en: 'Dark theme active',         hi: 'डार्क थीम चालू',            mr: 'डार्क थीम चालू');
  String get lightModeActive     => _s(en: 'Light theme active',        hi: 'लाइट थीम चालू',             mr: 'लाइट थीम चालू');

  String get sectionLanguage     => _s(en: 'Language',                  hi: 'भाषा',                      mr: 'भाषा');
  String get languageSub         => _s(en: 'Canteen app language',      hi: 'कँटीन ॲप ची भाषा',          mr: 'कँटीन ॲप ची भाषा');

  String get sectionDevice       => _s(en: 'Device & Hardware',         hi: 'डिव्हाइस व हार्डवेअर',      mr: 'डिव्हाइस व हार्डवेअर');
  String get deviceHwSoon        => _s(en: 'Hardware integration coming soon', hi: 'हार्डवेअर लवकरच येईल', mr: 'हार्डवेअर लवकरच येणार');
  String get labelDeviceName     => _s(en: 'Device Name',               hi: 'डिव्हाइसचे नाव',            mr: 'डिव्हाइसचे नाव');
  String get labelCounterDevice  => _s(en: 'Counter Device',            hi: 'काउंटर डिव्हाइस',           mr: 'काउंटर डिव्हाइस');
  String get labelDeviceId       => _s(en: 'Device ID',                 hi: 'डिव्हाइस ID',               mr: 'डिव्हाइस ID');
  String get labelPrinterStatus  => _s(en: 'Printer Status',            hi: 'प्रिंटर स्थिती',             mr: 'प्रिंटर स्थिती');
  String get printerNotConnected => _s(en: 'Not Connected',             hi: 'जोडले नाही',                 mr: 'जोडले नाही');
  String get labelScannerStatus  => _s(en: 'Scanner Status',            hi: 'स्कॅनर स्थिती',              mr: 'स्कॅनर स्थिती');
  String get scannerReady        => _s(en: 'Ready',                     hi: 'तयार',                      mr: 'तयार');
  String get labelLastSync       => _s(en: 'Last Sync',                 hi: 'शेवटचा सिंक',               mr: 'शेवटचा सिंक');

  String get clearHistory        => _s(en: 'Clear Completed History',   hi: 'पूर्ण इतिहास साफ करा',       mr: 'पूर्ण इतिहास साफ करा');
  String get helpContact         => _s(en: 'Help & Contact',            hi: 'मदत व संपर्क',               mr: 'मदत व संपर्क');
  String get logout              => _s(en: 'Logout',                    hi: 'बाहेर पडा',                  mr: 'बाहेर पडा');

  // ── Profile Dialogs ───────────────────────────────────────────────────────

  String get clearHistoryTitle   => _s(en: 'Clear Completed History',   hi: 'पूर्ण इतिहास साफ करा',       mr: 'पूर्ण इतिहास साफ करा');
  String get clearHistoryBody    => _s(
    en: 'This will hide all completed orders from your canteen view.\n\n'
        'Orders, payment records, and reports are NOT deleted — '
        'they remain safely in the system.\n\n'
        'Student order history is also unaffected.\n\n'
        'Active, paid, and scheduled orders are NOT affected.',
    hi: 'तुमच्या कँटीन व्ह्यूमधून पूर्ण ऑर्डर लपतील.\n\n'
        'ऑर्डर, पेमेंट व रिपोर्ट डिलीट होत नाहीत — '
        'ते सिस्टीममध्ये सुरक्षित राहतात.\n\n'
        'विद्यार्थ्यांचा इतिहास बदलत नाही.\n\n'
        'सक्रिय, भरलेले व शेड्युल ऑर्डर प्रभावित होत नाहीत.',
    mr: 'तुमच्या कँटीन व्ह्यूमधून पूर्ण ऑर्डर लपतील.\n\n'
        'ऑर्डर, पेमेंट व अहवाल हटवले जात नाहीत — '
        'ते सिस्टीममध्ये सुरक्षित राहतात.\n\n'
        'विद्यार्थ्यांचा इतिहास बदलत नाही.\n\n'
        'सक्रिय, भरलेले व शेड्युल ऑर्डर याचा परिणाम होत नाही.',
  );
  String get clearFromView       => _s(en: 'Clear from View',           hi: 'व्ह्यूमधून साफ करा',          mr: 'व्ह्यूमधून साफ करा');
  String clearedCount(int n) => n == 1
      ? _s(en: 'Cleared 1 completed order', hi: '1 पूर्ण ऑर्डर साफ झाला', mr: '1 पूर्ण ऑर्डर साफ झाला')
      : _s(en: 'Cleared $n completed orders', hi: '$n पूर्ण ऑर्डर साफ झाले', mr: '$n पूर्ण ऑर्डर साफ झाले');


  String get logoutTitle         => _s(en: 'Logout',                    hi: 'लॉगआउट करें',               mr: 'बाहेर पडा');
  String get logoutBody          => _s(en: 'Are you sure you want to logout from canteen staff?',
                                       hi: 'क्या आप कैंटीन स्टाफ से लॉगआउट करना चाहते हैं?',
                                       mr: 'तुम्हाला कँटीन स्टाफमधून बाहेर पडायचे आहे का?');
  String get logoutConfirm       => _s(en: 'Logout',                    hi: 'लॉगआउट करें',               mr: 'बाहेर पडा');

  // ── Help Bottom Sheet ─────────────────────────────────────────────────────

  String get helpTitle           => _s(en: 'Help & Contact',            hi: 'मदत व संपर्क',               mr: 'मदत व संपर्क');
  String get helpCallAdmin       => _s(en: 'Call Canteen Admin',        hi: 'कँटीन अॅडमिन ला फोन करा',   mr: 'कँटीन अॅडमिन ला फोन करा');
  String get helpCallSub         => _s(en: '+91 98765 43210',           hi: '+91 98765 43210',            mr: '+91 98765 43210');
  String get helpMarkReady       => _s(en: 'How to mark an order ready', hi: 'ऑर्डर कसा तयार द्यायचा',   mr: 'ऑर्डर कसा तयार द्यायचा');
  String get helpMarkReadySub    => _s(en: 'Go to Verify tab → Scan student QR code',
                                       hi: 'वेरिफाय टॅबवर जा → विद्यार्थ्याचा QR स्कॅन करा',
                                       mr: 'तपासा टॅबवर जा → विद्यार्थ्याचा QR स्कॅन करा');
  String get helpPrintSlip       => _s(en: 'How to print a slip',       hi: 'स्लिप कशी प्रिंट करायची',    mr: 'स्लिप कशी छापायची');
  String get helpPrintSlipSub    => _s(en: 'Open order card → Tap "Open Slip" → Tap "Print & Mark"',
                                       hi: 'ऑर्डर कार्ड उघडा → "स्लिप पाहा" दाबा → "प्रिंट करा व नोंद करा" दाबा',
                                       mr: 'ऑर्डर कार्ड उघडा → "स्लिप उघडा" दाबा → "छापा व नोंद करा" दाबा');
  String get helpScheduled       => _s(en: 'Scheduled orders',          hi: 'शेड्युल ऑर्डर',              mr: 'शेड्युल ऑर्डर');
  String get helpScheduledSub    => _s(en: 'Appear in the Queue tab grouped by pickup time',
                                       hi: 'पिकअप वेळानुसार रांग टॅबमध्ये दिसतात',
                                       mr: 'वेळेनुसार रांग टॅबमध्ये दिसतात');
  String get helpClose           => _s(en: 'Close',                     hi: 'बंद करा',                    mr: 'बंद करा');

  // ── Reports Screen ────────────────────────────────────────────────────────

  String get reports             => _s(en: 'Reports',                   hi: 'रिपोर्ट',                   mr: 'अहवाल');
  String get reportsRefresh      => _s(en: 'Refresh reports',           hi: 'रिपोर्ट ताजे करा',           mr: 'अहवाल ताजे करा');
  String get reportsRetry        => _s(en: 'Retry',                     hi: 'पुन्हा प्रयत्न करा',         mr: 'पुन्हा करा');
  String get reportsLoadFail     => _s(en: 'Could not load reports',    hi: 'रिपोर्ट लोड होऊ शकला नाही', mr: 'अहवाल लोड झाला नाही');
  String get reportsThisMonth    => _s(en: 'This Month',                hi: 'या महिन्यात',                mr: 'या महिन्यात');
  String get reportsTopItems     => _s(en: 'Top Ordered Items',         hi: 'सर्वाधिक ऑर्डर केलेले',      mr: 'सर्वाधिक ऑर्डर');
  String get reportsNoSales      => _s(en: 'No sales data yet',         hi: 'अजून विक्री नाही',           mr: 'अजून विक्री नाही');
  String get reportsTodayOrders  => _s(en: "Today's Orders",            hi: 'आजचे ऑर्डर',                mr: 'आजचे ऑर्डर');
  String get reportsTodayRevenue => _s(en: "Today's Revenue",           hi: 'आजची कमाई',                 mr: 'आजची कमाई');
  String reportsOrdersAvg(int count, String avg) => _s(
    en: '$count orders · avg $avg/day',
    hi: '$count ऑर्डर · सरासरी $avg/दिन',
    mr: '$count ऑर्डर · सरासरी $avg/दिन',
  );
  String reportsToday(String date) => _s(
    en: 'Today — $date',
    hi: 'आज — $date',
    mr: 'आज — $date',
  );

  // ── Internal helper ───────────────────────────────────────────────────────

  String _s({required String en, required String hi, required String mr}) {
    switch (languageCode) {
      case 'hi': return hi;
      case 'mr': return mr;
      default:   return en;
    }
  }
}
