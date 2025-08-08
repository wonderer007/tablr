// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import NotificationDropdownController from "controllers/notification_dropdown_controller"
import AlertController from "controllers/alert_controller"
import CarouselController from "controllers/carousel_controller"
import ModalController from "controllers/modal_controller"
application.register("notification-dropdown", NotificationDropdownController)
application.register("alert", AlertController)
application.register("carousel", CarouselController)
application.register("modal", ModalController)
eagerLoadControllersFrom("controllers", application)
