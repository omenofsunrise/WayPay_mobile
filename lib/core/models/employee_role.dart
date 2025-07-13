enum EmployeeRole { accountant, employee, admin, superAdmin, director }

enum Permission { createCredits, deleteCredits }

extension EmployeeRoleMapper on EmployeeRole {
  static EmployeeRole fromApi(String apiValue) {
    switch (apiValue.toLowerCase()) {
      case 'бухгалтер':
        return EmployeeRole.accountant;
      case 'сотрудник':
        return EmployeeRole.employee;
      case 'админ':
        return EmployeeRole.admin;
      case 'суперадмин':
        return EmployeeRole.superAdmin;
      case 'директор':
        return EmployeeRole.director;
      default:
        throw Exception('Неизвестная роль: $apiValue');
    }
  }
}

extension PermissionMapper on Permission {
  static Permission fromApi(String apiValue) {
    switch (apiValue.toUpperCase()) {
      case 'CREATE_CREDITS':
        return Permission.createCredits;
      case 'DELETE_CREDITS':
        return Permission.deleteCredits;
      default:
        throw Exception('Неизвестное разрешение: $apiValue');
    }
  }
}
