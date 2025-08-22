import 'package:waypay/features/clients/data/models/clients/client_response_model.dart';
import 'package:waypay/features/clients/data/models/clients/get_clients_query.dart';

abstract class BlacklistRemoteDataSources {
  Future<ClientsResponseModel> getClientsBlacklist(GetClientsQuery query);
  Future<void> toBlackList(int id);
  Future<void> fromBlackList(int id);
}
