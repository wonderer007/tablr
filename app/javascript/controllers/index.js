// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import NotificationDropdownController from "controllers/notification_dropdown_controller"
import AlertController from "controllers/alert_controller"
application.register("notification-dropdown", NotificationDropdownController)
application.register("alert", AlertController)
eagerLoadControllersFrom("controllers", application)
