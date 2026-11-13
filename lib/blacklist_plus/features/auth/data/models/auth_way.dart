enum AuthWay {
  callCheck('CallCheck'),
  whatsAppCode('WhatsAppCode');

  const AuthWay(this.apiValue);

  final String apiValue;
}
