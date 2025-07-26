// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import NotificationDropdownController from "controllers/notification_dropdown_controller"
application.register("notification-dropdown", NotificationDropdownController)
eagerLoadControllersFrom("controllers", application)
