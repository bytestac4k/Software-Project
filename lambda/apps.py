import json, os, uuid, boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

def _claims(event):
    return (event.get("requestContext", {})
                .get("authorizer", {})
                .get("jwt", {})
                .get("claims", {}))

def _groups(claims):
    g = claims.get("cognito:groups", [])
    if isinstance(g, str):
        return [x.strip() for x in g.split(",") if x.strip()]
    return g or []

def _resp(status, body):
    return {"statusCode": status, "headers": {"content-type": "application/json"}, "body": json.dumps(body)}

def handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    claims = _claims(event)
    groups = _groups(claims)

    is_admin  = "Admin" in groups
    is_member = "Member" in groups or is_admin

    if method == "GET":
        # GET /?id=uuid → get one; else list
        qp = event.get("queryStringParameters") or {}
        item_id = qp.get("id")
        if not is_member:
            return _resp(403, {"error": "forbidden"})
        if item_id:
            r = table.get_item(Key={"id": item_id})
            return _resp(200, r.get("Item", {}))
        r = table.scan(Limit=50)
        return _resp(200, r.get("Items", []))

    if not is_admin:
        return _resp(403, {"error": "forbidden"})

    body = json.loads(event.get("body") or "{}")

    if method == "POST":
        item_id = body.get("id") or str(uuid.uuid4())
        body["id"] = item_id
        table.put_item(Item=body)
        return _resp(201, {"ok": True, "id": item_id})

    if method == "PUT":
        if "id" not in body:
            return _resp(400, {"error": "id required"})
        table.put_item(Item=body)
        return _resp(200, {"ok": True, "id": body["id"]})

    if method == "DELETE":
        qp = event.get("queryStringParameters") or {}
        item_id = qp.get("id")
        if not item_id:
            return _resp(400, {"error": "id required"})
        table.delete_item(Key={"id": item_id})
        return _resp(200, {"ok": True})

    return _resp(405, {"error": "method not allowed"})
