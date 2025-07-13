class UpdateClientDocIssueDateRequest {
  final String? docIssueDate;

  UpdateClientDocIssueDateRequest({this.docIssueDate});

  Map<String, dynamic> toJson() {
    return {'docIssueDate': docIssueDate};
  }
}
