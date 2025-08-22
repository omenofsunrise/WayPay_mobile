import 'package:waypay/features/clients/data/models/clients/client_model.dart';
import 'package:waypay/features/clients/data/models/clients/client_response_model.dart';
import 'package:waypay/features/clients/data/models/clients/create_clients_requests.dart';
import 'package:waypay/features/clients/data/models/clients/get_clients_query.dart';
import 'package:waypay/features/clients/data/models/clients/update_client_doc_issue_date_requests.dart';
import 'package:waypay/features/clients/data/models/clients/update_client_doc_request.dart';
import 'package:waypay/features/clients/data/models/clients/update_client_request.dart';

abstract class ClientRemoteDataSource {
  Future<ClientsResponseModel> getClients(GetClientsQuery query);
  Future<ClientModel> getClientById(int id);
  Future<void> deleteClient(int id);
  Future<void> updateClientBasic(int id, UpdateClientRequest request);
  Future<void> updateClientDoc(int id, UpdateClientDocRequest request);
  Future<void> updateClientDocIssueDate(int id, UpdateClientDocIssueDateRequest request);
  Future<void> createClient(CreateClientRequest request);
}
