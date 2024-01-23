
<details>
<summary>Command output</summary>

```sh

kafka-console-consumer \
    --bootstrap-server localhost:19092,localhost:19093,localhost:19094 \
    --topic _auditLogs \
    --from-beginning \
    --timeout-ms 3000 \
 | jq 'select(.type=="SAFEGUARD" and .eventData.plugin=="io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin")'
{
  "id": "0099d622-6e3a-423e-8165-77f769b7a5d6",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49037"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:26.079328468Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "8ad6ce53-f1a4-4e02-b366-a1739d984dfd",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49038"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:26.220261759Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "5e31dea0-f177-40ba-bc0e-256634e71711",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49039"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:26.457403385Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "a6c2be0b-1b51-45ec-acbb-6dfcdb77e52c",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49040"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:26.697302176Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "94136c68-4200-4c82-9ac5-d1e897af37d2",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49041"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:27.140973468Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "78b4f258-4b88-4480-abab-c5263b97a798",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49042"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:28.187130010Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "0e5b9688-5d32-4cf9-a56b-c9e0c6625367",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49043"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:29.223316469Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "b8fc15ff-1369-4ba4-9560-ce023edd5684",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49044"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:30.263958303Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "e894e14b-cfbb-41bf-b22b-adcf6f3a0382",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49045"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:31.411930762Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "bff27d16-aef4-42d1-8ca6-d2c2fcfaee3c",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49046"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:32.352924846Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "741b856b-9888-4b82-898a-2a8ae2e6a1ed",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49047"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:33.310467430Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "3dbf8ebb-bdc2-4e77-9e8c-ac680c1e8e1f",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49048"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:34.361390722Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "784ee4a8-a84c-424c-a831-4edf9492e164",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49049"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:35.431763166Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "6faacdc9-2b90-4728-a31e-7930b1a66786",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49050"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:36.463817917Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "9a4040f6-f383-466c-9572-f62614bee2fd",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49051"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:37.405619042Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "d991f6ac-b161-4ea5-afd9-339c4bbf6332",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49052"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:38.449592209Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "6da13fb1-b017-491d-a6e0-6e951450e057",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49053"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:39.714087627Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "65ccce5f-86a4-40f5-8d97-fc8ae3d15e6c",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49054"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:40.556794377Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "70bf128c-38af-4390-81be-66eee5adbefa",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49055"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:41.616054169Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "8124584d-695c-4582-886e-dca442ffac88",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49056"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:42.688449461Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "5ca18767-8c5a-4ac9-a45c-46940204b3b0",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49057"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:43.743730795Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "02959b58-2c60-41d2-863c-3f38dfce735a",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49058"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:45.012171129Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "9b54cb29-ad9e-4b72-b371-6a282984d17e",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49059"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:46.190872380Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "ca0cbaa1-58fc-44a6-823c-928ca06068ee",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49060"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:47.262427797Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "91015926-fa2a-4710-9f79-7f188641ec64",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49061"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:48.323098672Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "bae3e55f-d49d-475f-b51b-ce4b15778e46",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49062"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:49.486771840Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "98eb02cc-4a6f-4a4f-8050-adf4f27fc549",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49063"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:50.575116882Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "ff5f4daa-603a-43ac-b08c-8058df8e7f92",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49064"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:51.514186841Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "37b5bc98-fc69-4850-9139-eb34c9bafe25",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49065"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:52.471556133Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "3c418147-cb2a-462b-8c74-d216418821e5",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49066"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:53.631245383Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "173e0b92-af6d-4da1-86c1-d2d634601a2f",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49067"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:54.770576884Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "cf14da27-4e87-42df-bc89-732fc104fa16",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49068"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:55.853982926Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "6f0b911a-a370-4666-9f05-83b22952206f",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49069"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:56.862797468Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "b301df98-bc38-4d44-a4ad-99262bf2e16f",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49070"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:58.029692260Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "111a07f8-82e1-40b0-8554-22300939e2a2",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49071"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:33:59.088476178Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "936d99f2-139f-4a14-9b65-c77b4628b9fb",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49072"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:00.231670636Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "6cf75681-6327-4877-88c1-beedfb53e289",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49073"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:01.390663929Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "38b698d4-9d21-4e48-9e32-2bb2a43a0439",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49074"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:02.344866679Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "75cacd21-d6ac-489f-bb49-683aa91b407a",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49075"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:03.607330680Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "d5223d8b-6a18-4729-8eb7-0413defe8061",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49076"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:04.589046680Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "ce2c5aab-d128-45a1-9fd7-d9125447745a",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49077"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:05.704253208Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "6943b2c3-0391-4402-a8fe-f6ecc1709bd0",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49078"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:06.844674917Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "39b886ed-136b-4ee2-870f-678895477b57",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49079"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:07.787423584Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "d183de53-9733-46fd-95b4-31e13f2661ae",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49080"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:08.930725876Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "f943ece4-0c7d-45fe-a7a8-41c0f0e81801",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49081"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:09.969343543Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "970f596d-eb05-47e2-a40f-ae59a88ebced",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49082"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:11.113709961Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "99176ff8-f702-40ae-bb2d-0e51bac8bbd9",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49083"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:12.057872544Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "68727c02-5ff1-4d91-a6ea-80f842aa8c72",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49084"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:13.111657545Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "fcf83ffa-c6d3-444d-b6ef-ebbac8b51e7a",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49085"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:14.253104129Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "40621600-c43f-4510-97d0-2abdf4188152",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49086"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:15.388899879Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "f6822f3c-035e-4bc4-8bec-c381b84cb969",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49087"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:16.427418338Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "5c0869ba-c091-454b-89be-8cf7b08b714b",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49088"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:17.577570839Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "d31fd1f7-ff41-41b3-8013-2029066837c7",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49089"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:19.040466131Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "61dc0b02-df56-403c-92b6-27fc4085192c",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49090"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:19.986578673Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "cl[2024-01-23 00:34:31,905] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 127 messages
ientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "b569599d-fd65-4be7-b36e-9ef61eb2ed33",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49091"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:21.123046132Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "2e90ee85-63ef-49e3-915f-5f7d991e6cbc",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49092"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:22.100517966Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "ec9fb898-112f-4155-ba9c-80eb08b7a1ea",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49093"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:23.270785966Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "92cd7aaf-7d9a-4693-b3a8-bfeae1bb1628",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49094"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:24.525541050Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}
{
  "id": "8548759e-9e87-46d9-98c9-649ae6765032",
  "source": "krn://cluster=EOp8W_dfTYC47C-jO17DoQ",
  "type": "SAFEGUARD",
  "authenticationPrincipal": "teamA",
  "userName": "sa",
  "connection": {
    "localAddress": null,
    "remoteAddress": "/192.168.65.1:49095"
  },
  "specVersion": "0.1.0",
  "time": "2024-01-22T23:34:25.807931426Z",
  "eventData": {
    "level": "error",
    "plugin": "io.conduktor.gateway.interceptor.safeguard.ClientIdRequiredPolicyPlugin",
    "message": "clientId 'adminclient-1' is invalid, naming convention must match with regular expression 'naming-convention-.*'"
  }
}

```

</details>
      
