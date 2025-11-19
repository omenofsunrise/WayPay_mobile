import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waypay_mobile/assets/resources.dart';

void main() {
  test('svg_icons assets test', () {
    expect(File(SvgIcons.add).existsSync(), isTrue);
    expect(File(SvgIcons.allCredits).existsSync(), isTrue);
    expect(File(SvgIcons.analyticsLogo).existsSync(), isTrue);
    expect(File(SvgIcons.arrowBack).existsSync(), isTrue);
    expect(File(SvgIcons.bell).existsSync(), isTrue);
    expect(File(SvgIcons.blog).existsSync(), isTrue);
    expect(File(SvgIcons.blogLogo).existsSync(), isTrue);
    expect(File(SvgIcons.book).existsSync(), isTrue);
    expect(File(SvgIcons.calcLogo).existsSync(), isTrue);
    expect(File(SvgIcons.calculator).existsSync(), isTrue);
    expect(File(SvgIcons.calendar).existsSync(), isTrue);
    expect(File(SvgIcons.cash).existsSync(), isTrue);
    expect(File(SvgIcons.chartIcon).existsSync(), isTrue);
    expect(File(SvgIcons.chat).existsSync(), isTrue);
    expect(File(SvgIcons.chat2).existsSync(), isTrue);
    expect(File(SvgIcons.chatLogo).existsSync(), isTrue);
    expect(File(SvgIcons.chevronLeft).existsSync(), isTrue);
    expect(File(SvgIcons.clockIcon).existsSync(), isTrue);
    expect(File(SvgIcons.companyAmount).existsSync(), isTrue);
    expect(File(SvgIcons.coolicon).existsSync(), isTrue);
    expect(File(SvgIcons.credits).existsSync(), isTrue);
    expect(File(SvgIcons.currencyDollar).existsSync(), isTrue);
    expect(File(SvgIcons.debt).existsSync(), isTrue);
    expect(File(SvgIcons.debtSelf).existsSync(), isTrue);
    expect(File(SvgIcons.delay).existsSync(), isTrue);
    expect(File(SvgIcons.docIcon).existsSync(), isTrue);
    expect(File(SvgIcons.fileDigit).existsSync(), isTrue);
    expect(File(SvgIcons.filter).existsSync(), isTrue);
    expect(File(SvgIcons.home).existsSync(), isTrue);
    expect(File(SvgIcons.importantCredits).existsSync(), isTrue);
    expect(File(SvgIcons.inactiveCredits).existsSync(), isTrue);
    expect(File(SvgIcons.investition).existsSync(), isTrue);
    expect(File(SvgIcons.investorAmount).existsSync(), isTrue);
    expect(File(SvgIcons.investorCahs).existsSync(), isTrue);
    expect(File(SvgIcons.investorIcon).existsSync(), isTrue);
    expect(File(SvgIcons.investorPercent).existsSync(), isTrue);
    expect(File(SvgIcons.logo).existsSync(), isTrue);
    expect(File(SvgIcons.moneyIcon).existsSync(), isTrue);
    expect(File(SvgIcons.moneybag).existsSync(), isTrue);
    expect(File(SvgIcons.newCredit).existsSync(), isTrue);
    expect(File(SvgIcons.notebook).existsSync(), isTrue);
    expect(File(SvgIcons.search).existsSync(), isTrue);
    expect(File(SvgIcons.shieldPerson).existsSync(), isTrue);
    expect(File(SvgIcons.todoCopy).existsSync(), isTrue);
    expect(File(SvgIcons.todo).existsSync(), isTrue);
    expect(File(SvgIcons.users).existsSync(), isTrue);
    expect(File(SvgIcons.vectorLogoBlack).existsSync(), isTrue);
  });
}
