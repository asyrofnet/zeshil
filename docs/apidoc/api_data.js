define({ "api": [
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/admin/applications",
    "title": "Add New Application",
    "name": "AddApplication",
    "group": "Admin___Application",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "app_id",
            "description": "<p>Application id, like <code>qisme</code> or <code>kiwari-prod</code>. Please don't input any string with spaces, it just alphanumeric only</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "app_name",
            "description": "<p>Application name</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "description",
            "description": "<p>Application description</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "qiscus_sdk_secret",
            "description": "<p>Qiscus SDK secret</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "phone_number",
            "description": "<p>Phone number for default admin of this application</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": true,
            "field": "fullname",
            "defaultValue": "Admin",
            "description": "<p>Default admin's fullname of this application</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "gender",
            "description": "<p>Default admin's gender, <code>male</code> or <code>female</code> only.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/applications_controller.rb",
    "groupTitle": "Admin___Application",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/applications"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/applications",
    "title": "Index All Registered Application",
    "name": "AllApplication",
    "group": "Admin___Application",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "app_id",
            "description": "<p>Filter by application id scope name with no space, i.e: <code>qisme</code>, <code>kiwari-prod</code></p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "app_name",
            "description": "<p>Filter by application name</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Page number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/applications_controller.rb",
    "groupTitle": "Admin___Application",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/applications"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/applications/:id/users",
    "title": "Get users of an application",
    "name": "ApplicationUsers",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "group": "Admin___Application",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>Application id to update</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "fullname",
            "description": "<p>Filter by fullname</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "email",
            "description": "<p>Filter by email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "phone_number",
            "description": "<p>Filter by phone_number</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Page number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/applications_controller.rb",
    "groupTitle": "Admin___Application",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/applications/:id/users"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/admin/applications/:id",
    "title": "Delete Application",
    "name": "DeleteApplication",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "description": "<p>For security reason, admin can only destroy their own application. Admin can't delete other application even if he was created that application.</p>",
    "group": "Admin___Application",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>Application id to update</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/applications_controller.rb",
    "groupTitle": "Admin___Application",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/applications/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/applications/:id",
    "title": "Show detail of an application",
    "name": "ShowApplication",
    "group": "Admin___Application",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>Application id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/applications_controller.rb",
    "groupTitle": "Admin___Application",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/applications/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "patch",
    "url": "/api/v1/admin/applications/:id",
    "title": "Update Application",
    "name": "UpdateApplication",
    "group": "Admin___Application",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>Application id to update</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "app_name",
            "description": "<p>Application name</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "description",
            "description": "<p>Application description</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "qiscus_sdk_secret",
            "description": "<p>Qiscus SDK secret</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/applications_controller.rb",
    "groupTitle": "Admin___Application",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/applications/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/admin/auth/resend",
    "title": "Admin Login Resend Passcode",
    "description": "<p>Resend passcode for admin login</p>",
    "name": "AdminAuthResendPasscode",
    "group": "Admin___Auth",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>User application id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Registered phone number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/auth_controller.rb",
    "groupTitle": "Admin___Auth",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/auth/resend"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/admin/auth",
    "title": "Admin Login",
    "description": "<p>Try to looking for user with given phone number and role = admin</p>",
    "name": "AdminLogin",
    "group": "Admin___Auth",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Phone number to be register or sign in</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/auth_controller.rb",
    "groupTitle": "Admin___Auth",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/auth"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/admin/auth/verify",
    "title": "Verify Admin Login passcode from SMS",
    "description": "<p>Return access token and user object if successful</p>",
    "name": "AdminLoginAuthVerify",
    "group": "Admin___Auth",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Phone number to validate</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[passcode]",
            "description": "<p>Passcode from SMS</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/auth_controller.rb",
    "groupTitle": "Admin___Auth",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/auth/verify"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/chat_rooms",
    "title": "Index All Chat Room",
    "name": "AdminAllChatRoom",
    "description": "<p>Index all chat room. Admin will only see chat room in their scope (same application id) and can not see chat room in other application scope</p>",
    "group": "Admin___Chat_Rooms",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "qiscus_room_name",
            "description": "<p>Filter by qiscus room name</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "group_chat_name",
            "description": "<p>Filter by group chat name</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Page number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/chat_rooms_controller.rb",
    "groupTitle": "Admin___Chat_Rooms",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/chat_rooms"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/admin/chat_rooms/:id/change_group_name",
    "title": "Change Chat Room Name",
    "name": "AdminChangeChatRoomName",
    "group": "Admin___Chat_Rooms",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>Chat room id in qisme engine</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "group_chat_name",
            "description": "<p>New group name</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/chat_rooms_controller.rb",
    "groupTitle": "Admin___Chat_Rooms",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/chat_rooms/:id/change_group_name"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/chat_rooms/:id",
    "title": "Show Chat Room",
    "name": "AdminShowChatRoom",
    "group": "Admin___Chat_Rooms",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>Chat room id in qisme engine</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/chat_rooms_controller.rb",
    "groupTitle": "Admin___Chat_Rooms",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/chat_rooms/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/roles",
    "title": "List of Roles",
    "name": "AdminListofRoles",
    "group": "Admin___Role_Management",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/roles_controller.rb",
    "groupTitle": "Admin___Role_Management",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/roles"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/statistics",
    "title": "Application statistics",
    "name": "AdminApplicationStatisctic",
    "group": "Admin___Statistics",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "description": "<p>It will return user total, registered user per month, chat total, chat per month, chat per type (single or group)</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          }
        ]
      }
    },
    "success": {
      "examples": [
        {
          "title": "Success-Response:",
          "content": "{ \"data\": { \"user\": { \"total\": 61, \"user_register\": [ { \"month\": \"Mar 2017\", \"total_user\": 44 }, { \"month\": \"Apr 2017\", \"total_user\": 17 } ] }, \"chat\": { \"all_total\": 89, \"single_chat_total\": 34, \"group_chat_total\": 55, \"average_group_participant\": 1, \"all\": [ { \"month\": \"Mar 2017\", \"total_user\": 37 }, { \"month\": \"Apr 2017\", \"total_user\": 52 } ], \"group\": [ { \"month\": \"Mar 2017\", \"total\": 31 }, { \"month\": \"Apr 2017\", \"total\": 24 } ], \"single\": [ { \"month\": \"Apr 2017\", \"total\": 28 }, { \"month\": \"Mar 2017\", \"total\": 6 } ] } } }",
          "type": "json"
        }
      ]
    },
    "filename": "app/controllers/api/v1/admin/statistics_controller.rb",
    "groupTitle": "Admin___Statistics",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/statistics"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/admin/users",
    "title": "Create User",
    "name": "AdminCreateUser",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>User phone number (must valid phone number)</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[email]",
            "description": "<p>User email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[fullname]",
            "description": "<p>User name</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[gender]",
            "description": "<p>User gender (male or female)</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[date_of_birth]",
            "description": "<p>User date of birth (format: <code>YYYY-mm-dd</code>)</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[is_public]",
            "description": "<p>Profile status (true or false)</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[description]",
            "description": "<p>User status or official account description</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[callback_url]",
            "description": "<p>Callback url for Bot account (official account)</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "user[role_id]",
            "description": "<p>[] Add roles. For example you cand send <code>user[role_id][]=1&amp;user[role_id][]=2</code> or <code>user[role_id]=1</code>. By default member role will be assigned if you don't send anything.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/admin/users/:id",
    "title": "Delete User By Id",
    "name": "AdminDeleteUserById",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>User id to delete</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/users/import_template",
    "title": "Download Import User Template",
    "name": "AdminDownloadImportUserTemplate",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/import_template"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/users/:id",
    "title": "Get User By Id",
    "name": "AdminGetUserById",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>User id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/admin/users/import",
    "title": "Import User",
    "name": "AdminImportUser",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "File",
            "optional": false,
            "field": "raw_file",
            "description": "<p>CSV file contains data to import (must follows import template)</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/import"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/users/officials",
    "title": "List of Official User",
    "description": "<p>You can use get <code>/api/v1/admin/users.csv</code> to export using same params.</p>",
    "name": "AdminListofOfficialUser",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "email",
            "description": "<p>Filter by email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "fullname",
            "description": "<p>Filter by fullname</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "phone_number",
            "description": "<p>Filter by phone_number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/officials"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/users/officials_all",
    "title": "List of Official User Without Pagination",
    "name": "AdminListofOfficialUserWithoutPagination",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "email",
            "description": "<p>Filter by email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "fullname",
            "description": "<p>Filter by fullname</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "phone_number",
            "description": "<p>Filter by phone_number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/officials_all"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/users",
    "title": "List of User",
    "description": "<p>You can use get <code>/api/v1/admin/users.csv</code> to export using same params.</p>",
    "name": "AdminListofUser",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "email",
            "description": "<p>Filter by email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "fullname",
            "description": "<p>Filter by fullname</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "phone_number",
            "description": "<p>Filter by phone_number</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Pagination number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/users/all",
    "title": "List of User Without Pagination",
    "name": "AdminListofUserWithoutPagination",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "email",
            "description": "<p>Filter by email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "fullname",
            "description": "<p>Filter by fullname</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "phone_number",
            "description": "<p>Filter by phone_number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/all"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/admin/users/:id/contacts",
    "title": "Show User Contacts By Id",
    "description": "<p>You can use get <code>/api/v1/admin/users.csv</code> to export using same params.</p>",
    "name": "AdminShowUserContact",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>User id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "email",
            "description": "<p>Filter by contact email of this user</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "fullname",
            "description": "<p>Filter by contact fullname of this user</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "phone_number",
            "description": "<p>Filter by contact phone_number of this user</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Pagination number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:id/contacts"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/admin/users/:id/update_avatar",
    "title": "Update User Avatar",
    "name": "AdminUpdateUserAvatar",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>User id to update</p>"
          },
          {
            "group": "Parameter",
            "type": "File",
            "optional": false,
            "field": "avatar_file",
            "description": "<p>Picture file for new avatar</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:id/update_avatar"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "patch",
    "url": "/api/v1/admin/users/:id",
    "title": "Update User By Id",
    "name": "AdminUpdateUserById",
    "group": "Admin___User",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "user[id]",
            "description": "<p>User id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Update phone number (must valid phone number)</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[fullname]",
            "description": "<p>Update name</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[email]",
            "description": "<p>Update email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[gender]",
            "description": "<p>Update gender (male or female)</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[date_of_birth]",
            "description": "<p>Update date of birth (format: <code>YYYY-mm-dd</code>)</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[is_public]",
            "description": "<p>Profile status</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[description]",
            "description": "<p>User status or official account description</p>"
          },
          {
            "group": "Parameter",
            "type": "File",
            "optional": false,
            "field": "user[avatar_file]",
            "description": "<p>Update avatar</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[callback_url]",
            "description": "<p>Callback url for Bot account (official account)</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "user[role_id]",
            "description": "<p>[] Add roles. For example you cand send <code>user[role_id][]=1&amp;user[role_id]=[]2</code> or <code>user[role_id]=1</code></p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users_controller.rb",
    "groupTitle": "Admin___User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/admin/users/:id/roles",
    "title": "Add Role to This User",
    "name": "AdminAddRoletoThisUser",
    "group": "Admin___User_Role_Management",
    "description": "<p>Add Role to This User</p>",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>User id</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "role_id[]",
            "description": "<p>Role id to be added</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users/roles_controller.rb",
    "groupTitle": "Admin___User_Role_Management",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:id/roles"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/admin/users/:id/roles",
    "title": "Delete Role of This User",
    "name": "AdminDeleteRoleofThisUser",
    "group": "Admin___User_Role_Management",
    "description": "<p>Delete Role of This User</p>",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>User id</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "role_id[]",
            "description": "<p>Role id to be deleted</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users/roles_controller.rb",
    "groupTitle": "Admin___User_Role_Management",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:id/roles"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/users/:id/roles",
    "title": "List of User Roles",
    "name": "AdminListofUserRoles",
    "group": "Admin___User_Role_Management",
    "description": "<p>Show current user's roles</p>",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>User id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users/roles_controller.rb",
    "groupTitle": "Admin___User_Role_Management",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:id/roles"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/admin/users/:user_id/sessions/:session_id",
    "title": "Delete User Session",
    "description": "<p>Delete user session</p>",
    "name": "AdminUserSessionDelete",
    "group": "Admin___User_Sessions",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "user_id",
            "description": "<p>User id</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "session_id",
            "description": "<p>Session id of this user</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users/sessions_controller.rb",
    "groupTitle": "Admin___User_Sessions",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:user_id/sessions/:session_id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/users/:user_id/sessions",
    "title": "List User Session",
    "description": "<p>All user session for given user id</p>",
    "name": "AdminUserSessionIndex",
    "group": "Admin___User_Sessions",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "user_id",
            "description": "<p>User id</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Page number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users/sessions_controller.rb",
    "groupTitle": "Admin___User_Sessions",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:user_id/sessions"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/admin/users/:user_id/flush_sessions",
    "title": "Delete User Sessions",
    "description": "<p>Delete all session of this user</p>",
    "name": "AdminUserSessionsDelete",
    "group": "Admin___User_Sessions",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "user_id",
            "description": "<p>User id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/users/sessions_controller.rb",
    "groupTitle": "Admin___User_Sessions",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/users/:user_id/flush_sessions"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/announcements",
    "title": "Announcement List",
    "name": "AnnouncementList",
    "group": "Announcement",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Page number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/announcements_controller.rb",
    "groupTitle": "Announcement",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/announcements"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/announcements/last",
    "title": "Get Newst Announcements",
    "name": "GetNewestAnnouncement",
    "group": "Announcement",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/announcements_controller.rb",
    "groupTitle": "Announcement",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/announcements/last"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth/verify",
    "title": "Verify passcode from SMS",
    "description": "<p>Return access token and user object if successful</p>",
    "name": "AuthVerify",
    "group": "Auth",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Phone number to validate</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[passcode]",
            "description": "<p>Passcode from SMS</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_controller.rb",
    "groupTitle": "Auth",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth/verify"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth",
    "title": "Login or Register",
    "description": "<p>Register user if not exist, otherwise only send passcode via SMS</p>",
    "name": "LoginOrRegister",
    "group": "Auth",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Phone number to be register or sign in</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_controller.rb",
    "groupTitle": "Auth",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth/resend_passcode",
    "title": "Resend passcode",
    "description": "<p>Resend passcode</p>",
    "name": "ResendPasscode",
    "group": "Auth",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>User application id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Registered phone number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_controller.rb",
    "groupTitle": "Auth",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth/resend_passcode"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth_email/verify",
    "title": "Verify passcode from Email",
    "description": "<p>Return access token and user object if successful</p>",
    "name": "AuthVerifyEmail",
    "group": "Auth_Email",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[email]",
            "description": "<p>Email to validate</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[passcode]",
            "description": "<p>Passcode from email</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_email_controller.rb",
    "groupTitle": "Auth_Email",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth_email/verify"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth_email",
    "title": "Login or Register",
    "description": "<p>Register user if not exist, otherwise only send passcode via email</p>",
    "name": "LoginOrRegisterEmail",
    "group": "Auth_Email",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[email]",
            "description": "<p>Valid email to be register or sign in</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_email_controller.rb",
    "groupTitle": "Auth_Email",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth_email"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth_email/resend_passcode",
    "title": "Resend passcode",
    "description": "<p>Resend passcode</p>",
    "name": "ResendPasscodeEmail",
    "group": "Auth_Email",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>User application id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[email]",
            "description": "<p>Registered email</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_email_controller.rb",
    "groupTitle": "Auth_Email",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth_email/resend_passcode"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth_email_nonce/verify",
    "title": "Verify passcode from Email",
    "description": "<p>Return access token and user object if successful</p>",
    "name": "AuthVerifyEmail",
    "group": "Auth_Email_Nonce",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[email]",
            "description": "<p>Email to validate</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[passcode]",
            "description": "<p>Passcode from email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[nonce]",
            "description": "<p>Nonce from SDK</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_email_nonce_controller.rb",
    "groupTitle": "Auth_Email_Nonce",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth_email_nonce/verify"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth_email_nonce",
    "title": "Login or Register",
    "description": "<p>Register user if not exist, otherwise only send passcode via email</p>",
    "name": "LoginOrRegisterEmail",
    "group": "Auth_Email_Nonce",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[email]",
            "description": "<p>Valid email to be register or sign in</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_email_nonce_controller.rb",
    "groupTitle": "Auth_Email_Nonce",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth_email_nonce"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth_email_nonce/resend_passcode",
    "title": "Resend passcode",
    "description": "<p>Resend passcode</p>",
    "name": "ResendPasscodeEmail",
    "group": "Auth_Email_Nonce",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>User application id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[email]",
            "description": "<p>Registered email</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_email_nonce_controller.rb",
    "groupTitle": "Auth_Email_Nonce",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth_email_nonce/resend_passcode"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth_nonce/verify",
    "title": "Verify passcode from SMS",
    "description": "<p>Return access token and user object if successful</p>",
    "name": "AuthVerify",
    "group": "Auth_Nonce",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Phone number to validate</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[passcode]",
            "description": "<p>Passcode from SMS</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[nonce]",
            "description": "<p>Nonce from SDK</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_nonce_controller.rb",
    "groupTitle": "Auth_Nonce",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth_nonce/verify"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth_nonce",
    "title": "Login or Register",
    "description": "<p>Register user if not exist, otherwise only send passcode via SMS</p>",
    "name": "LoginOrRegister",
    "group": "Auth_Nonce",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Phone number to be register or sign in</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_nonce_controller.rb",
    "groupTitle": "Auth_Nonce",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth_nonce"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/auth_nonce/resend_passcode",
    "title": "Resend passcode",
    "description": "<p>Resend passcode</p>",
    "name": "ResendPasscode",
    "group": "Auth_Nonce",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>User application id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Registered phone number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/auth_nonce_controller.rb",
    "groupTitle": "Auth_Nonce",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/auth_nonce/resend_passcode"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/change_group_avatar",
    "title": "Change Group Avatar",
    "description": "<p>Change Group Avatar, this will not change group avatar in SDK, so please change it manually</p>",
    "name": "ChangeGroupAvatar",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "chat_room_id",
            "description": "<p>Chat room id which will be changed, this is qiscus room id</p>"
          },
          {
            "group": "Parameter",
            "type": "File",
            "optional": false,
            "field": "group_avatar",
            "description": "<p>Image file</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/change_group_avatar"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/change_group_name",
    "title": "Change Group Name",
    "description": "<p>Change Group Name, this will not change group name in SDK, so please change it manually</p>",
    "name": "ChangeGroupName",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "chat_room_id",
            "description": "<p>Chat room id which will be renamed, this is qiscus room id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "group_chat_name",
            "description": "<p>New group chat name</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/change_group_name"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/chat/conversations/rooms",
    "title": "Get Conversation List",
    "name": "ChatList",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Pagination. Per page is 10 conversation.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/rooms"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/chat/conversations",
    "title": "Get Conversation List",
    "name": "ChatList",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Pagination. Per page is 10 conversation.</p>"
          },
          {
            "group": "Parameter",
            "type": "Boolean",
            "optional": true,
            "field": "get_all",
            "defaultValue": "false",
            "description": "<p>Show all conversation. Get_all = 'true' or 'false'</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/chat/conversations/:id",
    "title": "Show single chat",
    "description": "<p>show chat room detail</p>",
    "name": "ChatShow",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>Qisme chat room id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/group_chat",
    "title": "Create group chat with participants",
    "description": "<p>Create group chat with participants Please note that if initiator (your access token id) is official, it will be logged as target user id.</p>",
    "name": "CreateGroupChat",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "target_user_id[]",
            "description": "<p>Array of user id in Qisme database</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "qiscus_room_id",
            "description": "<p>Qiscus room id from SDK create_room. If client doesn't send this params, it's mean backend will create room in sdk</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": true,
            "field": "chat_name",
            "defaultValue": "Group Chat Name",
            "description": "<p>Group chat name</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": true,
            "field": "group_avatar_url",
            "defaultValue": "https://d1edrlpyc25xu0.cloudfront.net/kiwari-prod/image/upload/1yahAVOqLy/1510804279-default_group_avatar.png",
            "description": "<p>URL of picture for group avatar</p>"
          },
          {
            "group": "Parameter",
            "type": "Boolean",
            "optional": true,
            "field": "is_official_chat",
            "defaultValue": "false",
            "description": "<p>It is official group chat or not</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/group_chat"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations",
    "title": "Get or create room with target",
    "description": "<p>Get or create single chat</p>",
    "name": "CreateSingleChat",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "target_user_id",
            "description": "<p>User id in Qisme database</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "qiscus_room_id",
            "description": "<p>Qiscus room id from SDK get_or_create_room_with_target. If client doesn't send this params, it's mean backend will create room in sdk</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/chat/conversations/filter",
    "title": "Filter Conversation List",
    "name": "FilterChat",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "chat_room_type",
            "description": "<p>Chat room type : 'single' or 'group'</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/filter"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/chat/conversations/group_chat",
    "title": "Get Group Chat Info By Qiscus Room Id",
    "name": "GroupChatInfo",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "qiscus_room_id",
            "description": "<p>Qiscus room id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/group_chat_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/group_chat"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/join_room_with_unique_id",
    "title": "Join room with unique id",
    "description": "<p>Join room with unique id.</p>",
    "name": "JoinRoomWithUniqueId",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token.</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "creator_user_id",
            "description": "<p>It's official user_id.</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "unique_id",
            "description": "<p>Unique_id is combination of app_id, creator (official) qiscus_email, app_id using # as separator. For example unique_id = &quot;kiwari-prod#userid_001_62812345678987@kiwari-prod.com#kiwari-prod&quot;</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/join_room_with_unique_id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/post_comment",
    "title": "Post Comment",
    "description": "<p>Send message to SDK through Qisme engine</p>",
    "name": "PostComment",
    "group": "Chat",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "topic_id",
            "description": "<p>Chat room id which will be post</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "comment",
            "description": "<p>Message comment to send</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "type",
            "description": "<p>Message type <code>text</code> or <code>account_linking</code></p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "payload",
            "description": "<p>JSON string for payload, example: { &quot;url&quot;: &quot;http://google.com&quot;, &quot;redirect_url&quot;: &quot;http://google.com/redirect&quot;, &quot;params&quot;: { &quot;user_id&quot;: 1, &quot;topic_id&quot;: 1, &quot;button_text&quot;: &quot;ini button&quot;, &quot;view_title&quot;: &quot;title&quot; } }</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "Chat",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/post_comment"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/contacts",
    "title": "Add Contact",
    "description": "<p>Add new contact</p>",
    "name": "AddContact",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "contact_id",
            "description": "<p>User id to be add as contact</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/contacts/favorites",
    "title": "Add Contact as Favourite",
    "description": "<p>Mark contact as favourite</p>",
    "name": "AddFav",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "user_id",
            "description": "<p>Contact id to be added as favourite</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts/favorites_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts/favorites"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/contacts",
    "title": "Contact List",
    "name": "ContactList",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "show",
            "description": "<p>Possible value is: <code>all</code> to show all user within this application, <code>contact</code> to show only their contact, <code>official</code> to only show official account. If you don't send any parameter, it will be use previous logic, where <code>only</code> and <code>exclude</code> parameter stills work, otherwise that two parameter will not work.</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "page",
            "description": "<p>Page number</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "limit",
            "description": "<p>Limit</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "only",
            "description": "<p>Possible value is: <code>official</code>. If you use this parameter (<code>only=official</code>) you will only see official account member.</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "exclude",
            "description": "<p>Possible value is: <code>official</code>. If you use this parameter (<code>exclude=official</code>) you will see all contact except official account.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/contacts/delete_contact",
    "title": "Delete Contact",
    "description": "<p>Delete contact</p>",
    "name": "DeleteContact",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "contact_id",
            "description": "<p>User id to be deleted as contact</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts/delete_contact"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/contacts/favorites/:id",
    "title": "Remove Contact from Favourite",
    "description": "<p>where id is contact user id</p>",
    "name": "DeleteFav",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>Contact id to be deleted from favourites</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts/favorites_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts/favorites/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/contacts/favorites",
    "title": "List of favourite contacts",
    "description": "<p>show all favorited contact</p>",
    "name": "ListFav",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts/favorites_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts/favorites"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/contacts/officials",
    "title": "List of Official Account",
    "description": "<p>show all official account</p>",
    "name": "ListOfficialAccount",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts/officials_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts/officials"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/contacts/search",
    "title": "Search User",
    "description": "<p>Search user to be added as contact</p>",
    "name": "SearchUser",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "phone_number",
            "description": "<p>Registered phone number (must be include country code)</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts/search"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/contacts/search_by_email",
    "title": "Search User by Email",
    "description": "<p>Search user by registered email to be added as contact</p>",
    "name": "SearchUserByEmail",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "email",
            "description": "<p>Registered email</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts/search_by_email"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/contacts/search_by_qiscus_email",
    "title": "Search User by Qiscus Email",
    "description": "<p>Search user to be added as contact using qiscus email, only used in particular condition, not for adding contact</p>",
    "name": "SearchUserByQiscusEmail",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "qiscus_email",
            "description": "<p>User qiscus email</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts/search_by_qiscus_email"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/contacts/favorites/:id",
    "title": "Show Single Favourite Contact",
    "description": "<p>where id is contact user id</p>",
    "name": "ShowFav",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>Contact id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts/favorites_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts/favorites/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/contacts/sync",
    "title": "Sync Contact From Phone Book",
    "description": "<p>sync all phone number in user phone contact to be contact in qisme application client (mobile) will post an array of phone number, qisme engine will return all contact included added contact</p>",
    "name": "SyncPhoneContact",
    "group": "Contact",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "phone_number[]",
            "description": "<p>Array of normalized phone number, for instance: <code>phone_number[]=+62...&amp;phone_number[]=+62...</code></p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/contacts/sync_controller.rb",
    "groupTitle": "Contact",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/contacts/sync"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/files/uploader",
    "title": "Upload File",
    "description": "<p>This route is use by mobile client to upload file, and will return response from qiscus uploader (such as file url)</p>",
    "name": "Uploader",
    "group": "Files",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "File",
            "optional": false,
            "field": "raw_file",
            "description": "<p>Raw file to be uploaded (commonly is an image)</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/files/uploader_controller.rb",
    "groupTitle": "Files",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/files/uploader"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/:qiscus_room_id/admins",
    "title": "Add Group Admins",
    "name": "AddGroupAdmins",
    "group": "Group_Chat_Admin",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "qiscus_room_id",
            "description": "<p>Qiscus room id</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": true,
            "field": "user_id[]",
            "description": "<p>Array of integer of user id, e.g: <code>user_id[]=1&amp;user_id[]=2</code></p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": true,
            "field": "qiscus_email[]",
            "description": "<p>Array of registered qiscus email, e.g: <code>qiscus_email[]=userid_6_qismetest3.mailinator.com@qisme.com&amp;qiscus_email[]=userid_5_qismetest2.mailinator.com@qisme.com</code></p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/admins_controller.rb",
    "groupTitle": "Group_Chat_Admin",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/:qiscus_room_id/admins"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/chat/conversations/:qiscus_room_id/admins/",
    "title": "Delete Group Admins",
    "name": "DeleteGroupAdmins",
    "group": "Group_Chat_Admin",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "qiscus_room_id",
            "description": "<p>Qiscus room id</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": true,
            "field": "user_id[]",
            "description": "<p>Array of integer of user id, e.g: <code>user_id[]=1&amp;user_id[]=2</code></p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": true,
            "field": "qiscus_email[]",
            "description": "<p>Array of registered qiscus email, e.g: <code>qiscus_email[]=userid_6_qismetest3.mailinator.com@qisme.com&amp;qiscus_email[]=userid_5_qismetest2.mailinator.com@qisme.com</code></p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/admins_controller.rb",
    "groupTitle": "Group_Chat_Admin",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/:qiscus_room_id/admins/"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/chat/conversations/:qiscus_room_id/admins",
    "title": "Get Group Admins",
    "name": "GetGroupAdmins",
    "group": "Group_Chat_Admin",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "qiscus_room_id",
            "description": "<p>Qiscus room id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/admins_controller.rb",
    "groupTitle": "Group_Chat_Admin",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/:qiscus_room_id/admins"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/chat/conversations/:qiscus_room_id/participants",
    "title": "Delete Group Participants",
    "description": "<p>use this alias <code>POST /api/v1/chat/conversations/:qiscus_room_id/delete_participants</code> if you prefer POST method, since in Delete method will cause error when it requested by unstable connection in client side.</p>",
    "name": "DeleteAddParticipants",
    "group": "Group_Chat_Participant",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "qiscus_room_id",
            "description": "<p>Qiscus room id</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": true,
            "field": "user_id[]",
            "description": "<p>Array of integer of user id, e.g: <code>user_id[]=1&amp;user_id[]=2</code></p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": true,
            "field": "qiscus_email[]",
            "description": "<p>Array of registered qiscus email, e.g: <code>qiscus_email[]=userid_6_qismetest3.mailinator.com@qisme.com&amp;qiscus_email[]=userid_5_qismetest2.mailinator.com@qisme.com</code></p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "message",
            "description": "<p>Message to be posted they (participant[s]) is removed</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/participants_controller.rb",
    "groupTitle": "Group_Chat_Participant",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/:qiscus_room_id/participants"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/:qiscus_room_id/participants",
    "title": "Add Group Participants",
    "name": "GroupAddParticipants",
    "group": "Group_Chat_Participant",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "qiscus_room_id",
            "description": "<p>Qiscus room id</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": true,
            "field": "user_id[]",
            "description": "<p>Array of integer of user id, e.g: <code>user_id[]=1&amp;user_id[]=2</code></p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": true,
            "field": "qiscus_email[]",
            "description": "<p>Array of registered qiscus email, e.g: <code>qiscus_email[]=userid_6_qismetest3.mailinator.com@qisme.com&amp;qiscus_email[]=userid_5_qismetest2.mailinator.com@qisme.com</code></p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "message",
            "description": "<p>Message to be posted they (participant[s]) is added</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/participants_controller.rb",
    "groupTitle": "Group_Chat_Participant",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/:qiscus_room_id/participants"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/chat/conversations/:qiscus_room_id/participants",
    "title": "Get Group Participants",
    "name": "GroupParticipants",
    "group": "Group_Chat_Participant",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "qiscus_room_id",
            "description": "<p>Qiscus room id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/participants_controller.rb",
    "groupTitle": "Group_Chat_Participant",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/:qiscus_room_id/participants"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/:qiscus_room_id/leave_group",
    "title": "Leave Group",
    "name": "LeaveGroup",
    "group": "Group_Chat_Participant",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "qiscus_room_id",
            "description": "<p>Qiscus room id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/participants_controller.rb",
    "groupTitle": "Group_Chat_Participant",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/:qiscus_room_id/leave_group"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/mute_chats",
    "title": "Add Mute Chat Rooms",
    "description": "<p>Add Mute Chat Rooms</p>",
    "name": "AddMuteChatRooms",
    "group": "Mute_Chat_Rooms",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "qiscus_room_id[]",
            "description": "<p>Array of qiscus_room_id, e.g: <code>qiscus_room_id[]=1&amp;qiscus_room_id[]=2</code></p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/mute_chats_controller.rb",
    "groupTitle": "Mute_Chat_Rooms",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/mute_chats"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/chat/conversations/mute_chats",
    "title": "Delete Mute Chat Rooms",
    "description": "<p>Delete Mute Chat Rooms</p>",
    "name": "DeleteMuteChatRooms",
    "group": "Mute_Chat_Rooms",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "qiscus_room_id[]",
            "description": "<p>Array of qiscus_room_id, e.g: <code>qiscus_room_id[]=1&amp;qiscus_room_id[]=2</code></p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/mute_chats_controller.rb",
    "groupTitle": "Mute_Chat_Rooms",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/mute_chats"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/passcode/verify",
    "title": "Verify passcode from SMS",
    "description": "<p>Return access token and user object if successful</p>",
    "name": "PasscodeVerify",
    "group": "Passcode",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Phone number to validate</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[passcode]",
            "description": "<p>Passcode from SMS</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/passcode_controller.rb",
    "groupTitle": "Passcode",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/passcode/verify"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/passcode",
    "title": "Request passcode",
    "description": "<p>Request passcode for existing user</p>",
    "name": "RequestPasscode",
    "group": "Passcode",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[app_id]",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Phone number to be register or sign in</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/passcode_controller.rb",
    "groupTitle": "Passcode",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/passcode"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/pin_chats",
    "title": "Add Pin Chat Rooms",
    "description": "<p>Add Pin Chat Rooms</p>",
    "name": "AddPinChatRooms",
    "group": "Pin_Chat_Rooms",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "qiscus_room_id[]",
            "description": "<p>Array of qiscus_room_id, e.g: <code>qiscus_room_id[]=1&amp;qiscus_room_id[]=2</code></p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/pin_chats_controller.rb",
    "groupTitle": "Pin_Chat_Rooms",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/pin_chats"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/chat/conversations/pin_chats",
    "title": "Delete Pin Chat Rooms",
    "description": "<p>Delete Pin Chat Rooms</p>",
    "name": "DeletePinChatRooms",
    "group": "Pin_Chat_Rooms",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "qiscus_room_id[]",
            "description": "<p>Array of qiscus_room_id, e.g: <code>qiscus_room_id[]=1&amp;qiscus_room_id[]=2</code></p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/pin_chats_controller.rb",
    "groupTitle": "Pin_Chat_Rooms",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/pin_chats"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/chat/conversations/pin_chats",
    "title": "Get Pin Chat Rooms",
    "name": "ListPinChatRooms",
    "group": "Pin_Chat_Rooms",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations/pin_chats_controller.rb",
    "groupTitle": "Pin_Chat_Rooms",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/pin_chats"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/posts",
    "title": "Create or Share A Post",
    "description": "<p>Create post or sharing a post</p>",
    "name": "CreateOrSharePost",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "content",
            "description": "<p>Post text content</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "media[]",
            "description": "<p>Post media, must be an array of file. This is optional.</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "share_post_id",
            "defaultValue": "null",
            "description": "<p>Post to share. This is optional.</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": true,
            "field": "link",
            "defaultValue": "null",
            "description": "<p>Url media to share or included in post media. This is optional.</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": true,
            "field": "link_meta",
            "defaultValue": "null",
            "description": "<p>Link meta should contain pre-fetch data such as title or caption. This must be valid JSON string, otherwise will return error</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/posts/:post_id/comments",
    "title": "Create New Comments",
    "description": "<p>Create Post Comments</p>",
    "name": "CreatePostComments",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "post_id",
            "description": "<p>Post id</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "content",
            "description": "<p>Comment text content. Maximum length of comment is 400 character</p>"
          },
          {
            "group": "Parameter",
            "type": "Array",
            "optional": false,
            "field": "media[]",
            "description": "<p>Comment media, must be an array of file. This is optional.</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "parent_comment_id",
            "defaultValue": "null",
            "description": "<p>Parent comment id.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts/comments_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts/:post_id/comments"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/posts/:post_id/comments/:comment_id",
    "title": "Delete Own Comment",
    "description": "<p>Only Own Comment and Own Post Can Delete Comment</p>",
    "name": "DeleteComment",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "post_id",
            "description": "<p>Post id</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "comment_id",
            "description": "<p>Comment id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts/comments_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts/:post_id/comments/:comment_id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/me/posts/:post_id",
    "title": "Delete Own Post",
    "description": "<p>Delete Own Post</p>",
    "name": "DeleteOwnPost",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "post_id",
            "description": "<p>Post id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me/posts_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/posts/:post_id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/posts/:post_id",
    "title": "Delete Posts",
    "description": "<p>Delete Post, only post owner can delete a post. This is alias for delete <code>/api/v1/me/post/:post_id</code></p>",
    "name": "DeletePost",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "post_id",
            "description": "<p>Post id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts/:post_id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/posts",
    "title": "Get Posts",
    "description": "<p>Get Post</p>",
    "name": "GetPost",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Pagination. Per page is 25 record.</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": true,
            "field": "show_media_list_as",
            "description": "<p>You can show media as an object (will return first media), or as an array (will retun array of media). Default is return object. Possible value is <code>array</code> or <code>object</code>.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/posts/:post_id/comments",
    "title": "Get Post Comments",
    "description": "<p>Get Post Comments</p>",
    "name": "GetPostComments",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "post_id",
            "description": "<p>Post id</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Pagination. Per page is 25 record.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts/comments_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts/:post_id/comments"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/posts/:post_id/likes",
    "title": "Get Post Likes",
    "description": "<p>Get Post Likes</p>",
    "name": "GetPostLikes",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "post_id",
            "description": "<p>Post id</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Pagination. Per page is 25 record.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts/likes_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts/:post_id/likes"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/posts/:post_id",
    "title": "Get Updated Post History",
    "description": "<p>Get Updated Post History</p>",
    "name": "GetUpdatedPostHistory",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts/:post_id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/me/posts",
    "title": "Get Own Posts",
    "description": "<p>Get Own Post</p>",
    "name": "Get_Own_Post",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Pagination. Per page is 25 record.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me/posts_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/posts"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/posts/users/:user_id",
    "title": "Get User Posts",
    "description": "<p>Get User Posts</p>",
    "name": "Get_User_Posts",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "user_id",
            "description": "<p>User id</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Pagination. Per page is 25 record.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts/users_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts/users/:user_id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/posts/:post_id/likes",
    "title": "Like Post",
    "description": "<p>Like Post</p>",
    "name": "LikePost",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts/likes_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts/:post_id/likes"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/me/posts/:post_id/likes",
    "title": "Unlike Post",
    "description": "<p>Unlike post</p>",
    "name": "UnlikePost",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts/likes_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/posts/:post_id/likes"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "patch",
    "url": "/api/v1/posts/:post_id",
    "title": "Update Post",
    "description": "<p>Update Post</p>",
    "name": "UpdatePost",
    "group": "Post",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "content",
            "description": "<p>New content</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/posts_controller.rb",
    "groupTitle": "Post",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/posts/:post_id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/me/delete_device_token",
    "title": "Delete Device Token",
    "name": "Delete_Device_Token",
    "group": "Profile",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "devicetoken",
            "description": "<p>Device token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me_controller.rb",
    "groupTitle": "Profile",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/delete_device_token"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/me/identity_token",
    "title": "Get Identity Token",
    "name": "Get_Identity_Token",
    "group": "Profile",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "nonce",
            "description": "<p>Nonce from SDK</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me_controller.rb",
    "groupTitle": "Profile",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/identity_token"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/me/logout",
    "title": "Logout session",
    "description": "<p>This endpoint to ensure there are not trash data in auth_sessions table, since all jwt token are now saved in database, it better to delete it manually</p>",
    "name": "LogoutSession",
    "group": "Profile",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "devicetoken",
            "description": "<p>Device token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me_controller.rb",
    "groupTitle": "Profile",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/logout"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "delete",
    "url": "/api/v1/me/sessions/:session_id",
    "title": "Delete My Session",
    "description": "<p>Delete session. You cannot delete current session, if you want to destroy current session use <code>GET /api/v1/me/logout</code> instead.</p>",
    "name": "Me",
    "group": "Profile",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "session_id",
            "description": "<p>Session id to be deleted</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me/sessions_controller.rb",
    "groupTitle": "Profile",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/sessions/:session_id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/me",
    "title": "My Profile",
    "name": "Me",
    "group": "Profile",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me_controller.rb",
    "groupTitle": "Profile",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/me/sessions",
    "title": "List My Active Session",
    "description": "<p>Get all active session except current session for this user to force logout</p>",
    "name": "Me",
    "group": "Profile",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": true,
            "field": "page",
            "defaultValue": "1",
            "description": "<p>Page number</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me/sessions_controller.rb",
    "groupTitle": "Profile",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/sessions"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/me/features",
    "title": "My Active Features",
    "name": "My_Active_Features",
    "group": "Profile",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me_controller.rb",
    "groupTitle": "Profile",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/features"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/me/register_device_token",
    "title": "Register Device Token",
    "name": "Register_Device_Token",
    "group": "Profile",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "devicetoken",
            "description": "<p>Device token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user_type",
            "description": "<p>Device platform : 'android' or 'ios'</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me_controller.rb",
    "groupTitle": "Profile",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/register_device_token"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/me/update_avatar",
    "title": "Update Profile Avatar",
    "name": "UpdateAvatarProfile",
    "group": "Profile",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "File",
            "optional": false,
            "field": "avatar_file",
            "description": "<p>Image file</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me_controller.rb",
    "groupTitle": "Profile",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/update_avatar"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/me/update_profile",
    "title": "Update Profile",
    "name": "UpdateProfile",
    "group": "Profile",
    "description": "<p>Before updating user's email or phone number, system will check whether there are no another user who have same email/phone number except current user. Why this should be considered? For example there are 2 user: A and B registered in same application (id). A register using phone number, let say 123. B register using email, let say b@mail.com.</p> <p>Now, image if we don't check anything about data existense and let A to update his profile email to b@mail.com and let B to update their phone number to 123 (actually it can't be done because of db validation). It will be result strange behaviour in login method, since it just using one parameter, either email or phone number.</p> <p>Now, A have: 123, b@mail.com and B have: 123, b@mail.com It's the same data, and please forget about how it can be B know A's phone number or how it can A know B's email? The point is, it will led system have duplicate data (even it can't be done because of database validation). As we expected, when B try to login he will get authentication using id A. And when A try to login it will be A.</p>",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[fullname]",
            "description": "<p>Minimum 4 char maximum 20 char (as mentioned in specification <a href=\"https://quip.com/EafhASIYmym3\">https://quip.com/EafhASIYmym3</a>)</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[email]",
            "description": "<p>Valid email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[gender]",
            "description": "<p><code>male</code> or <code>female</code></p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[date_of_birth]",
            "description": "<p>Date of birth, format <code>yyyy-mm-dd</code></p>"
          },
          {
            "group": "Parameter",
            "type": "Boolean",
            "optional": false,
            "field": "user[is_public]",
            "description": "<p>Profile information is public or not</p>"
          },
          {
            "group": "Parameter",
            "type": "Text",
            "optional": false,
            "field": "user[description]",
            "description": "<p>Profile description (this is a profile status)</p>"
          },
          {
            "group": "Parameter",
            "type": "Text",
            "optional": false,
            "field": "user[country_name]",
            "description": "<p>Country (this is for buddygo support)</p>"
          },
          {
            "group": "Parameter",
            "type": "Text",
            "optional": false,
            "field": "user[secondary_phone_number]",
            "description": "<p>Secondary phone number (this is for buddygo support)</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/me_controller.rb",
    "groupTitle": "Profile",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/me/update_profile"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/push_notifications",
    "title": "Send push notifications",
    "description": "<p>Send push notification to spesific user</p>",
    "name": "PushNotification",
    "group": "PushNotification",
    "header": {
      "fields": {
        "Header": [
          {
            "group": "Header",
            "type": "String",
            "optional": false,
            "field": "Content-Type",
            "description": "<p>Content type, must be <code>application/json</code></p>"
          }
        ]
      },
      "examples": [
        {
          "title": "Request-Example:",
          "content": "{ \"Content-Type\": \"application/json\" }",
          "type": "json"
        }
      ]
    },
    "parameter": {
      "examples": [
        {
          "title": "Request-Example:",
          "content": "  {\n    \"access_token\": \"jwt_key\",\n    \"user_id\": 100,\n    \"pn_payload\": {\n        \"title\": \"New Message\",\n        \"body\": \"You have a new message.\",\n        \"payload\": {\n              \"key\": \"value\",\n          }\n     }\n}",
          "type": "JSON"
        }
      ],
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "user_id",
            "description": "<p>Target user id</p>"
          },
          {
            "group": "Parameter",
            "type": "Json",
            "optional": false,
            "field": "pn_payload",
            "description": "<p>Payload to send to target user</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/push_notifications_controller.rb",
    "groupTitle": "PushNotification",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/push_notifications"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/rest/conversations/create_room_with_unique_id",
    "title": "Create room with unique id",
    "description": "<p>Create room with unique id. It's for buddygo support. This room called public chat room</p>",
    "name": "CreateRoomWithUniqueId",
    "group": "Rest_API",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "server_key",
            "description": "<p>Valid server key</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user_id",
            "description": "<p>Valid user_id to be create room with unique id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/rest/conversations_controller.rb",
    "groupTitle": "Rest_API",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/rest/conversations/create_room_with_unique_id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/rest/auth_email",
    "title": "Login or Register using Server Key",
    "description": "<p>Register user if not exist, otherwise only send passcode via email</p>",
    "name": "LoginOrRegisterEmail",
    "group": "Rest_API",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "server_key",
            "description": "<p>Valid server key</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[email]",
            "description": "<p>Valid email to be register or sign in</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[name]",
            "description": "<p>Valid name to be register or sign in</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[phone_number]",
            "description": "<p>Valid phone_number to be register or sign in</p>"
          },
          {
            "group": "Parameter",
            "type": "Boolean",
            "optional": false,
            "field": "user[is_official]",
            "description": "<p>Is_official = 'true' or 'false' Set true if you want to create an official account</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user[avatar_url]",
            "description": "<p>Valid avatar_url to be register or sign in. It's optional</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/rest/auth_email_controller.rb",
    "groupTitle": "Rest_API",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/rest/auth_email"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/chat/conversations/post_system_event_message",
    "title": "Post system event message",
    "description": "<p>Post system event message type &quot;custom&quot;</p>",
    "name": "PostSystemEventMessage",
    "group": "System_Event_Message",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "target_email",
            "description": "<p>It's using qiscus_email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "message",
            "description": "<p>Message will be sent</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "payload",
            "description": "<p>Payload must be json object string</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "extras",
            "description": "<p>Extras must be json object string</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/chat/conversations_controller.rb",
    "groupTitle": "System_Event_Message",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/chat/conversations/post_system_event_message"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/calls",
    "title": "System event message for call",
    "description": "<p>System event message for call</p>",
    "name": "SystemEventMessageForCall",
    "group": "System_Event_Message",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user_email",
            "description": "<p>It's using qiscus_email</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "user_type",
            "description": "<p>User_type = 'caller' or 'callee'</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "call_room_id",
            "description": "<p>It's generated by client</p>"
          },
          {
            "group": "Parameter",
            "type": "Boolean",
            "optional": false,
            "field": "is_video",
            "description": "<p>Is_video = 'true' or 'false'</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "call_event",
            "description": "<p>Call_event = 'incoming', 'accept', 'end', 'cancel', 'reject'. incoming and cancel send from caller user. accept, reject send from callee user. end can be send from caller and callee user.</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/calls_controller.rb",
    "groupTitle": "System_Event_Message",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/calls"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/users/:id",
    "title": "Show Detail User",
    "description": "<p>where id is user id</p>",
    "name": "ShowUser",
    "group": "User",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>User access token</p>"
          },
          {
            "group": "Parameter",
            "type": "Number",
            "optional": false,
            "field": "id",
            "description": "<p>User id</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/users_controller.rb",
    "groupTitle": "User",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/users/:id"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/utilities/mobile_apps_version",
    "title": "Check Mobile Apps Version",
    "description": "<p>Check latest mobile apps version in database (for force update)</p>",
    "name": "CheckMobileAppsVersion",
    "group": "Utilities",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "app_id",
            "description": "<p>Application id, 'qisme', 'kiwari-stag', etc</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "platform",
            "description": "<p>Application platform: 'android', 'ios'</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "version",
            "description": "<p>Application version number (can be in version format like '1.1.1')</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/utilities/mobile_apps_version_controller.rb",
    "groupTitle": "Utilities",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/utilities/mobile_apps_version"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/admin/utilities/mobile_apps_version",
    "title": "Create Mobile Apps Version",
    "description": "<p>Update or create mobile version to force update</p>",
    "name": "MobileAppsVersionCreate",
    "group": "Utilities_Mobile_Application",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "platform",
            "description": "<p>Mobile platform</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "version",
            "description": "<p>Mobile version</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/utilities/mobile_apps_version_controller.rb",
    "groupTitle": "Utilities_Mobile_Application",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/utilities/mobile_apps_version"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "get",
    "url": "/api/v1/admin/utilities/mobile_apps_version",
    "title": "List Mobile Apps Version",
    "description": "<p>List of registered mobile version</p>",
    "name": "MobileAppsVersionList",
    "group": "Utilities_Mobile_Application",
    "permission": [
      {
        "name": "Admin"
      }
    ],
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "access_token",
            "description": "<p>Admin access token</p>"
          }
        ]
      }
    },
    "filename": "app/controllers/api/v1/admin/utilities/mobile_apps_version_controller.rb",
    "groupTitle": "Utilities_Mobile_Application",
    "sampleRequest": [
      {
        "url": "https://qisme-stag.qiscus.com/api/v1/admin/utilities/mobile_apps_version"
      }
    ]
  },
  {
    "version": "1.0.0",
    "type": "post",
    "url": "/api/v1/webhooks/bot-callback/:app_id",
    "title": "General Callback",
    "name": "BotCallbackController",
    "group": "Webhooks",
    "description": "<p>Akan mengembalikan payload yang kemudian dikirim ke <code>callback_url</code>, kembalian dari callback url akan diproses/langsung dikirim sebagai post comment, lihat kelas <code>CallbackBotPostcommentWorker</code></p>",
    "header": {
      "fields": {
        "Header": [
          {
            "group": "Header",
            "type": "String",
            "optional": false,
            "field": "Content-Type",
            "description": "<p>Content type, must be <code>application/json</code></p>"
          }
        ]
      },
      "examples": [
        {
          "title": "Request-Example:",
          "content": "{ \"Content-Type\": \"application/json\" }",
          "type": "json"
        }
      ]
    },
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "json",
            "optional": false,
            "field": "payload",
            "description": "<p>Callback message type, must be sent in request body</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "optional": false,
            "field": "app_id",
            "description": "<p>Application id where this callback should be processed</p>"
          }
        ]
      },
      "examples": [
        {
          "title": "Request-Example:",
          "content": "  {\n    \"type\": \"post_comment\",\n    \"payload\": {\n        \"from\": {\n            \"id\": 1,\n            \"email\": \"userid_14_6281328777777@qisme.com\",\n            \"name\": \"User1\"\n        },\n        \"room\": {\n            \"id\": 536,\n            \"topic_id\": 536,\n            \"type\": \"group\",\n            \"name\": \"ini grup\",\n            \"participants\": [\n                {\n                    \"id\": 1,\n                    \"email\": \"userid_14_6281328777777@qisme.com\",\n                    \"username\": \"User1\",\n                    \"avatar_url\": \"http://avatar1.jpg\"\n                },\n                {\n                    \"id\": 2,\n                    \"email\": \"userid_12_6281328123455@qisme.com\",\n                    \"username\": \"User2\",\n                    \"avatar_url\": \"http://avatar2.jpg\"\n                }\n            ]\n        },\n        \"message\": {\n              \"type\": \"text\",\n              \"payload\": {},\n              \"text\": \"isi pesan\"\n          }\n     }\n}",
          "type": "json"
        }
      ]
    },
    "success": {
      "examples": [
        {
          "title": "Success-Response:",
          "content": "{\"success\":true,\"data\":[{\"callback_url\":\"http://localhost:3000/api/v1/listeners/telkom_news_bot_production\",\"token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxMiwidGltZXN0YW1wIjoiMjAxNy0wMy0yMSAxMTozNDo1NSArMDcwMCJ9.VKktM_aNHhLFk9OhB7FUsdagYlPE1e_FX5_Urf9cEb4\",\"api_base_url\":\"http://localhost:3000\",\"type\":\"post_comment\",\"application\":{\"id\":1,\"app_id\":\"qisme\",\"app_name\":\"Qisme Default Application\",\"description\":null,\"qiscus_sdk_url\":\"http://dragonfly.qiscus.com\",\"created_at\":\"2017-01-22T07:36:06.116Z\",\"updated_at\":\"2017-01-24T04:35:33.627Z\",\"qiscus_sdk_secret\":\"qisme-123\"},\"from\":{\"id\":14,\"phone_number\":\"+6281328777777\",\"fullname\":null,\"email\":null,\"gender\":null,\"date_of_birth\":null,\"avatar_url\":null,\"is_public\":false,\"verification_attempts\":0,\"created_at\":\"2017-03-15T09:32:33.748Z\",\"updated_at\":\"2017-03-16T03:38:33.975Z\",\"qiscus_email\":\"userid_14_6281328777777@qisme.com\",\"description\":\"\",\"callback_url\":\"\",\"is_admin\":false,\"is_official\":false,\"roles\":[{\"id\":2,\"name\":\"Member\"}],\"application\":{\"app_name\":\"Qisme Default Application\"},\"qiscus_id\":1},\"my_account\":{\"id\":12,\"phone_number\":\"+6281328123455\",\"fullname\":\"Telkom News Bot\",\"email\":null,\"gender\":null,\"date_of_birth\":null,\"avatar_url\":null,\"is_public\":false,\"verification_attempts\":0,\"created_at\":\"2017-03-15T04:46:12.981Z\",\"updated_at\":\"2017-03-21T04:34:47.797Z\",\"qiscus_email\":\"userid_12_6281328123455@qisme.com\",\"description\":\"\",\"callback_url\":\"http://localhost:3000/api/v1/listeners/telkom_news_bot_production\",\"is_admin\":false,\"is_official\":true,\"roles\":[{\"id\":2,\"name\":\"Member\"},{\"id\":3,\"name\":\"Official Account\"}],\"application\":{\"app_name\":\"Qisme Default Application\"}},\"chat_room\":{\"id\":9,\"qiscus_room_name\":\"CHat name\",\"qiscus_room_id\":536,\"is_group_chat\":true,\"created_at\":\"2017-03-15T05:30:47.931Z\",\"updated_at\":\"2017-03-15T05:30:47.931Z\",\"application_id\":1,\"group_avatar_url\":\"http://res.cloudinary.com/qiscus/image/upload/v1485166071/group_avatar_qisme_user_id_4/komqez5xtyjwsjrbaz7z.png\",\"is_official_chat\":true,\"users\":[{\"id\":12,\"phone_number\":\"+6281328123455\",\"fullname\":\"Telkom News Bot\",\"email\":null,\"gender\":null,\"date_of_birth\":null,\"avatar_url\":null,\"is_public\":false,\"verification_attempts\":0,\"created_at\":\"2017-03-15T04:46:12.981Z\",\"updated_at\":\"2017-03-21T04:34:47.797Z\",\"qiscus_email\":\"userid_12_6281328123455@qisme.com\",\"description\":\"\",\"callback_url\":\"http://localhost:3000/api/v1/listeners/telkom_news_bot_production\",\"is_admin\":false,\"is_official\":true,\"roles\":[{\"id\":2,\"name\":\"Member\"},{\"id\":3,\"name\":\"Official Account\"}],\"application\":{\"app_name\":\"Qisme Default Application\"},\"qiscus_id\":2},{\"id\":11,\"phone_number\":\"+6281328123456\",\"fullname\":\"Yusuf\",\"email\":null,\"gender\":null,\"date_of_birth\":null,\"avatar_url\":null,\"is_public\":false,\"verification_attempts\":1,\"created_at\":\"2017-03-15T04:45:36.367Z\",\"updated_at\":\"2017-03-15T04:45:47.539Z\",\"qiscus_email\":\"userid_11_6281328123456@qisme.com\",\"description\":\"\",\"callback_url\":\"\",\"is_admin\":false,\"is_official\":false,\"roles\":[{\"id\":2,\"name\":\"Member\"}],\"application\":{\"app_name\":\"Qisme Default Application\"}},{\"id\":13,\"phone_number\":\"+6281328123459\",\"fullname\":\"Helpdesk\",\"email\":null,\"gender\":null,\"date_of_birth\":null,\"avatar_url\":null,\"is_public\":false,\"verification_attempts\":1,\"created_at\":\"2017-03-15T05:47:41.093Z\",\"updated_at\":\"2017-03-15T05:49:05.981Z\",\"qiscus_email\":\"userid_13_6281328123459@qisme.com\",\"description\":\"\",\"callback_url\":\"\",\"is_admin\":false,\"is_official\":false,\"roles\":[{\"id\":2,\"name\":\"Member\"},{\"id\":5,\"name\":\"Helpdesk\"}],\"application\":{\"app_name\":\"Qisme Default Application\"}}],\"creator\":{\"id\":11,\"phone_number\":\"+6281328123456\",\"fullname\":\"Yusuf\",\"email\":null,\"gender\":null,\"date_of_birth\":null,\"avatar_url\":null,\"is_public\":false,\"verification_attempts\":1,\"created_at\":\"2017-03-15T04:45:36.367Z\",\"updated_at\":\"2017-03-15T04:45:47.539Z\",\"qiscus_email\":\"userid_11_6281328123456@qisme.com\",\"description\":\"\",\"callback_url\":\"\",\"is_admin\":false,\"is_official\":false,\"roles\":[{\"id\":2,\"name\":\"Member\"}],\"application\":{\"app_name\":\"Qisme Default Application\"}},\"chat_name\":\"CHat name\",\"chat_avatar_url\":\"http://res.cloudinary.com/qiscus/image/upload/v1485166071/group_avatar_qisme_user_id_4/komqez5xtyjwsjrbaz7z.png\"},\"message\":{\"payload\":\"JSON string payload\",\"text\":\"message content\",\"type\":\"menu or post comment or something\"}}]}",
          "type": "json"
        }
      ]
    },
    "filename": "app/controllers/api/v1/webhooks/bot_callback_controller.rb",
    "groupTitle": "Webhooks"
  }
] });
