from flask import jsonify


class ApiError(Exception):
    """Base for anything we deliberately return to a client.

    The `code` is the contract — clients branch on it. `message` is for
    humans reading logs, never for client-side logic.
    """

    status = 400
    code = "bad_request"

    def __init__(self, code=None, message=None, status=None, details=None):
        if code:
            self.code = code
        if status:
            self.status = status
        self.message = message or self.code.replace("_", " ")
        self.details = details
        super().__init__(self.message)

    def response(self):
        error = {"code": self.code, "message": self.message}
        if self.details:
            error["details"] = self.details
        return jsonify(error=error), self.status


class BadRequest(ApiError):
    status, code = 400, "bad_request"


class Unauthorized(ApiError):
    status, code = 401, "unauthorized"


class Forbidden(ApiError):
    status, code = 403, "forbidden"


class NotFound(ApiError):
    status, code = 404, "not_found"


class Conflict(ApiError):
    status, code = 409, "conflict"


class Gone(ApiError):
    status, code = 410, "gone"


class Unprocessable(ApiError):
    status, code = 422, "unprocessable"


def register_error_handlers(app):
    @app.errorhandler(ApiError)
    def handle_api_error(err):
        return err.response()

    @app.errorhandler(404)
    def handle_missing_route(_):
        return NotFound(message="no such route").response()

    @app.errorhandler(405)
    def handle_bad_method(_):
        return ApiError("method_not_allowed", status=405).response()

    @app.errorhandler(Exception)
    def handle_unexpected(err):
        # the old backend returned str(e) straight to the client, which leaked
        # schema and internal paths. log it, tell the client nothing.
        app.logger.exception("unhandled error: %s", err)
        return ApiError("internal_error", "something went wrong", 500).response()
