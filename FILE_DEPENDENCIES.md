# Internal File Dependencies

This document maps each Dart file in `lib/` to the other `lib/` files it imports.

## core/mixins/business/customer_communication_mixin.dart
- ../../data/models/business/customer.dart
- ../../data/providers/state/app_state_provider.dart
- ../../features/customers/presentation/widgets/enhanced_communication_dialog.dart
- communication_actions_mixin.dart

## core/mixins/business/file_sharing_mixin.dart
- ../../app/theme/rufko_theme.dart
- ../../data/models/business/customer.dart
- ../utils/helpers/common_utils.dart

## core/mixins/template_tab_mixin.dart
- ../data/providers/state/app_state_provider.dart

## core/mixins/ui/responsive_layout_mixin.dart
- responsive_breakpoints_mixin.dart
- responsive_dimensions_mixin.dart
- responsive_spacing_mixin.dart
- responsive_text_mixin.dart
- responsive_widget_mixin.dart

## core/mixins/ui/responsive_spacing_mixin.dart
- responsive_breakpoints_mixin.dart

## core/mixins/ui/responsive_text_mixin.dart
- responsive_breakpoints_mixin.dart

## core/mixins/ui/responsive_widget_mixin.dart
- responsive_breakpoints_mixin.dart
- responsive_dimensions_mixin.dart

## core/services/category_management_service.dart
- ../features/templates/presentation/widgets/dialogs/category_creation_dialog.dart
- ../features/templates/presentation/widgets/dialogs/category_selection_dialog.dart

## core/services/database/database_service.dart
- ../../data/models/business/customer.dart
- ../../data/models/business/product.dart
- ../../data/models/business/roof_scope_data.dart
- ../../data/models/business/simplified_quote.dart
- ../../data/models/media/inspection_document.dart
- ../../data/models/media/project_media.dart
- ../../data/models/settings/app_settings.dart
- ../../data/models/settings/custom_app_data.dart
- ../../data/models/templates/email_template.dart
- ../../data/models/templates/message_template.dart
- ../../data/models/templates/pdf_template.dart
- ../../data/models/templates/template_category.dart

## core/services/pdf/pdf_field_mapping_service.dart
- ../../data/models/business/customer.dart
- ../../data/models/business/simplified_quote.dart
- ../../data/models/templates/pdf_template.dart
- ../../data/providers/state/app_state_provider.dart

## core/services/pdf/pdf_service.dart
- ../../data/models/business/customer.dart
- ../../data/models/business/quote.dart
- ../../data/models/business/roof_scope_data.dart
- ../../data/models/business/simplified_quote.dart
- ../../data/models/templates/pdf_template.dart
- database/database_service.dart
- template_service.dart

## core/services/pdf/simple_pdf_editing_service.dart
- ../../data/models/media/project_media.dart
- ../utils/helpers/common_utils.dart

## core/services/settings_data_service.dart
- ../data/providers/state/app_state_provider.dart

## core/services/template_creation_service.dart
- ../shared/navigation/template_navigation_handler.dart
- category_management_service.dart

## core/services/template_management_service.dart
- ../data/models/templates/pdf_template.dart
- ../data/providers/state/app_state_provider.dart
- utils/template_validator.dart

## core/services/template_service.dart
- ../data/models/business/customer.dart
- ../data/models/business/product.dart
- ../data/models/business/quote.dart
- ../data/models/business/simplified_quote.dart
- ../data/models/templates/pdf_template.dart
- database/database_service.dart

## core/utils/helpers/pdf_utils.dart
- ../../data/models/business/customer.dart
- ../../data/models/business/simplified_quote.dart
- ../../data/providers/state/app_state_provider.dart
- ../../features/quotes/presentation/screens/pdf_preview_screen.dart

## core/utils/template_validator.dart
- ../data/models/templates/pdf_template.dart

## data/models/business/simplified_quote.dart
- quote.dart
- quote_extras.dart

## data/models/templates/pdf_template.dart
- business/product.dart
- ui/field_definition.dart

## data/providers/app_configuration_provider.dart
- ../core/services/database/database_service.dart
- ../core/services/external/tax_service.dart
- ../core/services/storage/file_service.dart
- models/settings/app_settings.dart

## data/providers/customer_provider.dart
- ../core/services/database/database_service.dart
- models/business/customer.dart

## data/providers/helpers/customer_helper.dart
- ../../core/services/database/database_service.dart
- ../models/business/customer.dart
- ../models/business/roof_scope_data.dart
- ../models/business/simplified_quote.dart
- ../models/media/project_media.dart

## data/providers/helpers/data_loading_helper.dart
- ../../core/services/database/database_service.dart
- ../models/business/customer.dart
- ../models/business/product.dart
- ../models/business/roof_scope_data.dart
- ../models/business/simplified_quote.dart
- ../models/media/inspection_document.dart
- ../models/media/project_media.dart
- ../models/settings/custom_app_data.dart
- ../models/templates/email_template.dart
- ../models/templates/message_template.dart
- ../models/templates/pdf_template.dart
- ../models/templates/template_category.dart

## data/providers/helpers/email_template_helper.dart
- ../../core/services/database/database_service.dart
- ../models/templates/email_template.dart

## data/providers/helpers/message_template_helper.dart
- ../../core/services/database/database_service.dart
- ../models/templates/message_template.dart

## data/providers/helpers/pdf_generation_helper.dart
- ../../core/services/pdf/pdf_service.dart
- ../../core/services/template_service.dart
- ../models/business/customer.dart
- ../models/business/simplified_quote.dart
- ../models/templates/pdf_template.dart

## data/providers/helpers/product_helper.dart
- ../../core/services/database/database_service.dart
- ../models/business/product.dart

## data/providers/helpers/quote_helper.dart
- ../../core/services/database/database_service.dart
- ../models/business/simplified_quote.dart

## data/providers/helpers/roof_scope_helper.dart
- ../models/business/roof_scope_data.dart

## data/providers/helpers/template_category_helper.dart
- ../../core/services/database/database_service.dart
- ../models/templates/template_category.dart

## data/providers/product_provider.dart
- ../core/services/database/database_service.dart
- models/business/product.dart

## data/providers/quote_provider.dart
- ../core/services/database/database_service.dart
- ../core/services/pdf/pdf_service.dart
- models/business/customer.dart
- models/business/simplified_quote.dart

## data/providers/state/app_state_provider.dart
- ../../core/services/database/database_service.dart
- ../../core/services/storage/file_service.dart
- ../models/business/customer.dart
- ../models/business/product.dart
- ../models/business/roof_scope_data.dart
- ../models/business/simplified_quote.dart
- ../models/media/inspection_document.dart
- ../models/media/project_media.dart
- ../models/settings/app_settings.dart
- ../models/settings/custom_app_data.dart
- ../models/templates/email_template.dart
- ../models/templates/message_template.dart
- ../models/templates/pdf_template.dart
- ../models/templates/template_category.dart
- app_configuration_provider.dart
- custom_fields_provider.dart
- customer_state_provider.dart
- helpers/data_loading_helper.dart
- helpers/pdf_generation_helper.dart
- helpers/roof_scope_helper.dart
- media_state_provider.dart
- product_state_provider.dart
- quote_state_provider.dart
- template_state_provider.dart

## data/providers/state/custom_fields_provider.dart
- ../../core/services/database/database_service.dart
- ../models/media/inspection_document.dart
- ../models/settings/custom_app_data.dart
- helpers/data_loading_helper.dart

## data/providers/state/customer_state_provider.dart
- ../../core/services/database/database_service.dart
- ../models/business/customer.dart
- ../models/business/roof_scope_data.dart
- ../models/business/simplified_quote.dart
- ../models/media/project_media.dart
- helpers/customer_helper.dart
- helpers/data_loading_helper.dart

## data/providers/state/media_state_provider.dart
- ../../core/services/database/database_service.dart
- ../models/media/project_media.dart
- helpers/data_loading_helper.dart

## data/providers/state/product_state_provider.dart
- ../../core/services/database/database_service.dart
- ../models/business/product.dart
- helpers/data_loading_helper.dart
- helpers/product_helper.dart

## data/providers/state/quote_state_provider.dart
- ../../core/services/database/database_service.dart
- ../../core/services/pdf/pdf_service.dart
- ../models/business/customer.dart
- ../models/business/simplified_quote.dart
- helpers/data_loading_helper.dart
- helpers/quote_helper.dart

## data/providers/state/template_state_provider.dart
- ../../core/services/database/database_service.dart
- ../../core/services/pdf/pdf_service.dart
- ../../core/services/template_service.dart
- ../models/business/customer.dart
- ../models/business/simplified_quote.dart
- ../models/templates/email_template.dart
- ../models/templates/message_template.dart
- ../models/templates/pdf_template.dart
- ../models/templates/template_category.dart
- helpers/data_loading_helper.dart
- helpers/email_template_helper.dart
- helpers/message_template_helper.dart
- helpers/pdf_generation_helper.dart
- helpers/template_category_helper.dart

## data/providers/template_provider.dart
- ../core/services/database/database_service.dart
- models/templates/email_template.dart
- models/templates/message_template.dart
- models/templates/pdf_template.dart
- models/templates/template_category.dart

## features/communication/presentation/controllers/communication_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/providers/state/app_state_provider.dart

## features/communication/presentation/controllers/communication_dialog_controller.dart
- communication_controller.dart

## features/communication/presentation/widgets/dialogs/email_edit_dialog.dart
- ../controllers/communication_dialog_controller.dart
- email_preview_dialog.dart

## features/communication/presentation/widgets/dialogs/email_preview_dialog.dart
- ../controllers/communication_dialog_controller.dart

## features/communication/presentation/widgets/dialogs/sms_edit_dialog.dart
- ../controllers/communication_dialog_controller.dart
- sms_preview_dialog.dart

## features/communication/presentation/widgets/dialogs/sms_preview_dialog.dart
- ../controllers/communication_dialog_controller.dart

## features/customers/data/repositories/customer_repository_impl.dart
- ../../../core/services/database/database_service.dart
- ../../../data/models/business/customer.dart
- ../domain/repositories/customer_repository.dart

## features/customers/domain/repositories/customer_repository.dart
- ../../../data/models/business/customer.dart

## features/customers/presentation/controllers/customer_actions_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/providers/state/app_state_provider.dart
- widgets/customer_edit_dialog.dart
- widgets/media_tab_controller.dart

## features/customers/presentation/controllers/customer_dialog_manager.dart
- ../../../data/models/business/customer.dart
- ../../../data/providers/state/app_state_provider.dart
- customer_import_controller.dart
- widgets/dialogs/customer_form_dialog.dart

## features/customers/presentation/controllers/customer_filter_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/providers/state/app_state_provider.dart

## features/customers/presentation/screens/customer_detail_screen.dart
- ../../../core/mixins/business/communication_actions_mixin.dart
- ../../../core/mixins/business/customer_communication_mixin.dart
- ../../../core/mixins/business/file_sharing_mixin.dart
- ../../../core/utils/helpers/common_utils.dart
- ../../../data/models/business/customer.dart
- ../../../data/providers/state/app_state_provider.dart
- ../../../shared/controllers/navigation_controller.dart
- ../../../shared/controllers/ui_state_controller.dart
- ../../communication/presentation/controllers/communication_controller.dart
- ../../communication/presentation/controllers/communication_dialog_controller.dart
- ../../communication/presentation/widgets/dialogs/email_edit_dialog.dart
- ../../communication/presentation/widgets/dialogs/email_preview_dialog.dart
- ../../communication/presentation/widgets/dialogs/sms_edit_dialog.dart
- ../../communication/presentation/widgets/dialogs/sms_preview_dialog.dart
- ../../media/presentation/controllers/media_selection_controller.dart
- controllers/customer_actions_controller.dart
- widgets/media_tab_controller.dart
- widgets/tabs/info_tab.dart
- widgets/tabs/inspection_tab.dart
- widgets/tabs/media_tab.dart
- widgets/tabs/quotes_tab.dart

## features/customers/presentation/screens/customers_screen.dart
- ../../../core/mixins/ui/empty_state_mixin.dart
- ../../../core/mixins/ui/search_mixin.dart
- ../../../core/mixins/ui/sort_menu_mixin.dart
- ../../../data/models/business/customer.dart
- ../../../data/providers/state/app_state_provider.dart
- controllers/customer_dialog_manager.dart
- controllers/customer_filter_controller.dart
- controllers/customer_import_controller.dart
- customer_detail_screen.dart
- widgets/customer_card.dart

## features/customers/presentation/widgets/category_media_screen.dart
- ../../../core/utils/helpers/common_utils.dart
- ../../../data/models/media/project_media.dart

## features/customers/presentation/widgets/customer_card.dart
- ../../../data/models/business/customer.dart

## features/customers/presentation/widgets/customer_edit_dialog.dart
- ../../../data/models/business/customer.dart
- ../../../data/providers/state/app_state_provider.dart

## features/customers/presentation/widgets/dialogs/customer_form_dialog.dart
- ../../../../data/models/business/customer.dart
- ../../../../data/providers/state/app_state_provider.dart

## features/customers/presentation/widgets/enhanced_communication_dialog.dart
- ../../../data/models/business/customer.dart
- ../../../data/providers/state/app_state_provider.dart

## features/customers/presentation/widgets/full_screen_image_viewer.dart
- ../../../data/models/media/project_media.dart

## features/customers/presentation/widgets/media_details_dialog.dart
- ../../../core/utils/helpers/common_utils.dart
- ../../../data/models/media/project_media.dart

## features/customers/presentation/widgets/media_tab_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/media/project_media.dart
- ../../../data/providers/state/app_state_provider.dart
- ../../quotes/presentation/screens/pdf_preview_screen.dart
- full_screen_image_viewer.dart
- media_details_dialog.dart

## features/customers/presentation/widgets/project_notes_section.dart
- ../../../data/models/business/customer.dart

## features/customers/presentation/widgets/tabs/info_tab.dart
- ../../../../core/utils/helpers/common_utils.dart
- ../../../../data/models/business/customer.dart
- ../../../../data/providers/state/app_state_provider.dart
- project_notes_section.dart

## features/customers/presentation/widgets/tabs/inspection_tab.dart
- ../../../../core/utils/helpers/common_utils.dart
- ../../../../data/models/business/customer.dart
- ../../../../data/models/media/inspection_document.dart
- ../../../../data/models/settings/custom_app_data.dart
- ../../../../data/providers/state/app_state_provider.dart
- ../../../media/presentation/screens/inspection_viewer_screen.dart

## features/customers/presentation/widgets/tabs/media_tab.dart
- ../../../../core/utils/helpers/common_utils.dart
- ../../../../data/models/business/customer.dart
- ../../../../data/models/media/project_media.dart
- ../../../../data/providers/state/app_state_provider.dart

## features/customers/presentation/widgets/tabs/quotes_tab.dart
- ../../../../data/models/business/customer.dart
- ../../../../data/models/business/simplified_quote.dart
- ../../../../data/providers/state/app_state_provider.dart

## features/dashboard/presentation/controllers/dashboard_data_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/providers/state/app_state_provider.dart

## features/dashboard/presentation/controllers/dashboard_ui_builder.dart
- ../../../app/theme/rufko_theme.dart
- ../../../core/mixins/ui/responsive_breakpoints_mixin.dart
- ../../../core/mixins/ui/responsive_dimensions_mixin.dart
- ../../../core/mixins/ui/responsive_spacing_mixin.dart
- ../../../core/mixins/ui/responsive_text_mixin.dart
- ../../../core/mixins/ui/responsive_widget_mixin.dart
- ../../../core/utils/helpers/dashboard_status_helper.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/simplified_quote.dart
- ../../customers/presentation/screens/customer_detail_screen.dart
- ../../quotes/presentation/screens/simplified_quote_detail_screen.dart
- dashboard_data_controller.dart
- dashboard_navigation_controller.dart

## features/dashboard/presentation/controllers/quick_actions_controller.dart
- ../../../core/mixins/ui/responsive_breakpoints_mixin.dart
- ../../../core/mixins/ui/responsive_dimensions_mixin.dart
- ../../../core/mixins/ui/responsive_spacing_mixin.dart
- ../../../core/mixins/ui/responsive_text_mixin.dart
- ../../../core/mixins/ui/responsive_widget_mixin.dart

## features/dashboard/presentation/screens/home_screen.dart
- ../../../app/theme/rufko_theme.dart
- ../../../core/mixins/ui/responsive_breakpoints_mixin.dart
- ../../../core/mixins/ui/responsive_dimensions_mixin.dart
- ../../../core/mixins/ui/responsive_spacing_mixin.dart
- ../../../core/mixins/ui/responsive_text_mixin.dart
- ../../../core/mixins/ui/responsive_widget_mixin.dart
- ../../../data/providers/state/app_state_provider.dart
- ../../customers/presentation/screens/customers_screen.dart
- ../../products/presentation/screens/products_screen.dart
- ../../quotes/presentation/screens/quotes_screen.dart
- ../../settings/presentation/screens/settings_screen.dart
- ../../templates/presentation/screens/templates_screen.dart
- controllers/dashboard_data_controller.dart
- controllers/dashboard_navigation_controller.dart
- controllers/dashboard_ui_builder.dart
- controllers/quick_actions_controller.dart
- widgets/home_layout_large.dart
- widgets/home_layout_small.dart

## features/media/presentation/controllers/media_selection_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/providers/state/app_state_provider.dart

## features/media/presentation/screens/inspection_viewer_screen.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/media/inspection_document.dart
- ../../../data/providers/state/app_state_provider.dart

## features/media/presentation/widgets/inspection_floating_button.dart
- ../../../data/models/business/customer.dart
- ../../../data/providers/state/app_state_provider.dart
- screens/inspection_viewer_screen.dart

## features/products/presentation/controllers/product_category_manager.dart
- ../../../data/providers/state/app_state_provider.dart

## features/products/presentation/controllers/product_dialog_manager.dart
- ../../../data/models/business/product.dart
- ../../../data/providers/state/app_state_provider.dart
- screens/product_form_dialog.dart

## features/products/presentation/controllers/product_filter_controller.dart
- ../../../data/models/business/product.dart
- ../../../data/providers/state/app_state_provider.dart

## features/products/presentation/screens/product_form_dialog.dart
- ../../../data/models/business/product.dart
- ../../../data/providers/state/app_state_provider.dart

## features/products/presentation/screens/products_screen.dart
- ../../../core/mixins/ui/empty_state_mixin.dart
- ../../../core/mixins/ui/search_mixin.dart
- ../../../core/mixins/ui/sort_menu_mixin.dart
- ../../../data/models/business/product.dart
- ../../../data/providers/state/app_state_provider.dart
- controllers/product_category_manager.dart
- controllers/product_dialog_manager.dart
- controllers/product_filter_controller.dart
- widgets/product_card.dart

## features/products/presentation/widgets/product_card.dart
- ../../../data/models/business/product.dart

## features/quotes/presentation/controllers/pdf_document_controller.dart
- ../../../data/models/ui/pdf_form_field.dart

## features/quotes/presentation/controllers/pdf_editing_controller.dart
- ../../../data/models/ui/edit_action.dart

## features/quotes/presentation/controllers/pdf_file_operations_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/models/media/project_media.dart
- ../../../data/models/ui/pdf_form_field.dart
- ../../../data/providers/state/app_state_provider.dart
- pdf_document_controller.dart

## features/quotes/presentation/controllers/pdf_generation_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/models/templates/pdf_template.dart
- ../../../data/providers/state/app_state_provider.dart
- screens/pdf_preview_screen.dart
- widgets/dialogs/template_selection_dialog.dart

## features/quotes/presentation/controllers/pdf_viewer_ui_builder.dart
- ../../../data/models/ui/pdf_form_field.dart
- pdf_editing_controller.dart

## features/quotes/presentation/controllers/quote_detail_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/providers/state/app_state_provider.dart
- pdf_generation_controller.dart

## features/quotes/presentation/controllers/quote_filter_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/providers/state/app_state_provider.dart

## features/quotes/presentation/controllers/quote_form_controller.dart
- ../../../app/constants/quote_form_constants.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/product.dart
- ../../../data/models/business/quote.dart
- ../../../data/models/business/quote_extras.dart
- ../../../data/models/business/roof_scope_data.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/providers/state/app_state_provider.dart
- screens/simplified_quote_detail_screen.dart
- widgets/dialogs/tax_rate_dialogs.dart

## features/quotes/presentation/controllers/quote_list_builder.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/providers/state/app_state_provider.dart
- quote_filter_controller.dart
- quote_navigation_controller.dart

## features/quotes/presentation/controllers/quote_navigation_controller.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/roof_scope_data.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/providers/state/app_state_provider.dart
- screens/simplified_quote_detail_screen.dart
- screens/simplified_quote_screen.dart

## features/quotes/presentation/screens/pdf_preview_screen.dart
- ../../../app/theme/rufko_theme.dart
- ../../../core/mixins/business/file_sharing_mixin.dart
- ../../../core/services/pdf/pdf_field_mapping_service.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/models/ui/pdf_form_field.dart
- ../../../data/providers/state/app_state_provider.dart
- ../../templates/presentation/controllers/template_field_dialog_manager.dart
- controllers/pdf_document_controller.dart
- controllers/pdf_editing_controller.dart
- controllers/pdf_file_operations_controller.dart
- controllers/pdf_viewer_ui_builder.dart

## features/quotes/presentation/screens/quotes_screen.dart
- ../../../core/mixins/ui/empty_state_mixin.dart
- ../../../core/mixins/ui/search_mixin.dart
- ../../../core/mixins/ui/sort_menu_mixin.dart
- ../../../data/providers/state/app_state_provider.dart
- controllers/quote_list_builder.dart
- controllers/quote_navigation_controller.dart

## features/quotes/presentation/screens/simplified_quote_detail_screen.dart
- ../../../app/theme/rufko_theme.dart
- ../../../core/mixins/ui/responsive_breakpoints_mixin.dart
- ../../../core/mixins/ui/responsive_dimensions_mixin.dart
- ../../../core/mixins/ui/responsive_spacing_mixin.dart
- ../../../core/mixins/ui/responsive_text_mixin.dart
- ../../../core/mixins/ui/responsive_widget_mixin.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/providers/state/app_state_provider.dart
- controllers/pdf_generation_controller.dart
- controllers/quote_detail_controller.dart
- simplified_quote_screen.dart
- widgets/cards/level_details_card.dart
- widgets/cards/level_selector_card.dart
- widgets/cards/quote_header_card.dart
- widgets/cards/quote_total_card.dart
- widgets/dialogs/discount_dialog.dart
- widgets/sections/addons_section.dart
- widgets/sections/discounts_section.dart

## features/quotes/presentation/screens/simplified_quote_screen.dart
- ../../../app/constants/quote_form_constants.dart
- ../../../app/theme/rufko_theme.dart
- ../../../core/mixins/ui/responsive_breakpoints_mixin.dart
- ../../../core/mixins/ui/responsive_dimensions_mixin.dart
- ../../../core/mixins/ui/responsive_spacing_mixin.dart
- ../../../core/mixins/ui/responsive_text_mixin.dart
- ../../../core/mixins/ui/responsive_widget_mixin.dart
- ../../../data/models/business/customer.dart
- ../../../data/models/business/product.dart
- ../../../data/models/business/quote.dart
- ../../../data/models/business/quote_extras.dart
- ../../../data/models/business/roof_scope_data.dart
- ../../../data/models/business/simplified_quote.dart
- ../../../data/providers/state/app_state_provider.dart
- ../../media/presentation/widgets/inspection_floating_button.dart
- controllers/quote_form_controller.dart
- widgets/dialogs/add_product_dialog.dart
- widgets/dialogs/custom_item_dialog.dart
- widgets/form/main_product_section.dart
- widgets/form/quote_generation_section.dart
- widgets/form/quote_products_section.dart
- widgets/quote_levels_preview.dart
- widgets/sections/custom_line_items_section.dart
- widgets/sections/permits_section.dart

## features/quotes/presentation/widgets/added_products_list.dart
- ../../../data/models/business/quote.dart

## features/quotes/presentation/widgets/cards/level_details_card.dart
- ../../../../data/models/business/simplified_quote.dart

## features/quotes/presentation/widgets/cards/level_selector_card.dart
- ../../../../data/models/business/simplified_quote.dart

## features/quotes/presentation/widgets/cards/quote_header_card.dart
- ../../../../data/models/business/customer.dart
- ../../../../data/models/business/simplified_quote.dart

## features/quotes/presentation/widgets/cards/quote_total_card.dart
- ../../../../data/models/business/simplified_quote.dart

## features/quotes/presentation/widgets/dialogs/add_product_dialog.dart
- ../../../../data/models/business/product.dart
- ../../../../data/models/business/quote.dart
- ../../../../data/providers/state/app_state_provider.dart

## features/quotes/presentation/widgets/dialogs/custom_item_dialog.dart
- ../../../../data/models/business/quote_extras.dart

## features/quotes/presentation/widgets/dialogs/discount_dialog.dart
- ../../../../app/theme/rufko_theme.dart
- ../../../../core/mixins/ui/responsive_breakpoints_mixin.dart
- ../../../../core/mixins/ui/responsive_spacing_mixin.dart
- ../../../../data/models/business/simplified_quote.dart

## features/quotes/presentation/widgets/dialogs/tax_rate_dialogs.dart
- ../../../../data/models/business/customer.dart
- ../../../../data/providers/state/app_state_provider.dart
- ../controllers/quote_form_controller.dart

## features/quotes/presentation/widgets/dialogs/template_selection_dialog.dart
- ../../../../data/models/templates/pdf_template.dart

## features/quotes/presentation/widgets/form/main_product_section.dart
- ../../../../core/mixins/ui/responsive_breakpoints_mixin.dart
- ../../../../core/mixins/ui/responsive_spacing_mixin.dart
- ../../../../data/models/business/product.dart
- main_product_selection.dart
- quote_type_selector.dart

## features/quotes/presentation/widgets/form/quote_generation_section.dart
- ../../../../core/mixins/ui/responsive_breakpoints_mixin.dart
- ../../../../core/mixins/ui/responsive_spacing_mixin.dart
- ../../../../data/models/business/simplified_quote.dart

## features/quotes/presentation/widgets/form/quote_products_section.dart
- ../../../../core/mixins/ui/responsive_breakpoints_mixin.dart
- ../../../../core/mixins/ui/responsive_spacing_mixin.dart
- ../../../../data/models/business/customer.dart
- ../../../../data/models/business/product.dart
- ../../../../data/models/business/quote.dart
- ../../../../data/models/business/quote_extras.dart
- ../../../../data/models/business/simplified_quote.dart
- added_products_list.dart
- sections/quote_totals_section.dart
- sections/tax_rate_section.dart

## features/quotes/presentation/widgets/main_product_selection.dart
- ../../../data/models/business/product.dart
- ../../../data/providers/state/app_state_provider.dart

## features/quotes/presentation/widgets/quote_levels_preview.dart
- ../../../data/models/business/product.dart
- ../../../data/models/business/simplified_quote.dart

## features/quotes/presentation/widgets/sections/addons_section.dart
- ../../../../data/models/business/simplified_quote.dart

## features/quotes/presentation/widgets/sections/custom_line_items_section.dart
- ../../../../data/models/business/quote_extras.dart

## features/quotes/presentation/widgets/sections/discounts_section.dart
- ../../../../data/models/business/simplified_quote.dart

## features/quotes/presentation/widgets/sections/permits_section.dart
- ../../../../data/models/business/quote_extras.dart

## features/quotes/presentation/widgets/sections/quote_totals_section.dart
- ../../../../data/models/business/product.dart
- ../../../../data/models/business/quote_extras.dart
- ../../../../data/models/business/simplified_quote.dart

## features/quotes/presentation/widgets/sections/tax_rate_section.dart
- ../../../../data/models/business/customer.dart
- ../../../../data/providers/state/app_state_provider.dart

## features/settings/presentation/screens/company_info_screen.dart
- ../../../data/models/settings/app_settings.dart
- ../../../data/providers/state/app_state_provider.dart
- widgets/company_logo_picker.dart

## features/settings/presentation/screens/data_management_screen.dart
- ../../../core/services/settings_data_service.dart
- ../../../data/providers/state/app_state_provider.dart
- widgets/settings_tile.dart

## features/settings/presentation/screens/discount_settings_screen.dart
- ../../../data/models/settings/app_settings.dart
- ../../../data/providers/state/app_state_provider.dart
- discount_settings_dialog.dart
- widgets/settings_tile.dart

## features/settings/presentation/screens/settings_screen.dart
- ../../../data/models/settings/app_settings.dart
- ../../../data/providers/state/app_state_provider.dart
- ../../../shared/widgets/dialogs/help_dialog.dart
- ../../../shared/widgets/dialogs/premium_feature_dialog.dart
- category_manager_dialog.dart
- company_info_screen.dart
- data_management_screen.dart
- discount_settings_screen.dart
- quote_levels_manager_dialog.dart
- units_manager_dialog.dart
- widgets/settings_section.dart

## features/settings/presentation/widgets/company_logo_picker.dart
- ../../../data/models/settings/app_settings.dart
- ../../../data/providers/state/app_state_provider.dart

## features/settings/presentation/widgets/settings_section.dart
- ../../../core/utils/settings_constants.dart
- ../../../data/models/settings/app_settings.dart
- ../../../data/providers/state/app_state_provider.dart
- settings_tile.dart

## features/templates/presentation/controllers/category_data_controller.dart
- ../../../data/providers/state/app_state_provider.dart

## features/templates/presentation/controllers/category_dialog_manager.dart
- ../../../app/theme/rufko_theme.dart
- category_operations_controller.dart

## features/templates/presentation/controllers/category_operations_controller.dart
- ../../../data/providers/state/app_state_provider.dart
- category_data_controller.dart

## features/templates/presentation/controllers/category_ui_builder.dart
- ../../../app/theme/rufko_theme.dart
- ../../../data/providers/state/app_state_provider.dart
- category_data_controller.dart
- category_dialog_manager.dart

## features/templates/presentation/controllers/template_field_dialog_manager.dart
- ../../../core/services/pdf/pdf_field_mapping_service.dart
- ../../quotes/presentation/controllers/pdf_editing_controller.dart

## features/templates/presentation/screens/category_management_screen.dart
- ../../../app/theme/rufko_theme.dart
- controllers/category_data_controller.dart
- controllers/category_dialog_manager.dart
- controllers/category_operations_controller.dart
- controllers/category_ui_builder.dart

## features/templates/presentation/screens/template_editor_screen.dart
- ../../../app/theme/rufko_theme.dart
- ../../../core/services/pdf/pdf_field_mapping_service.dart
- ../../../core/services/pdf/pdf_interaction_service.dart
- ../../../core/services/template_management_service.dart
- ../../../data/models/templates/pdf_template.dart
- ../../../data/providers/state/app_state_provider.dart
- ../../../shared/widgets/common/loading_overlay.dart
- ../../quotes/presentation/screens/pdf_preview_screen.dart
- widgets/editor/field_mapping_bottom_sheet.dart
- widgets/editor/field_selection_dialog.dart
- widgets/editor/mapping_mode_banner.dart
- widgets/editor/pdf_viewer_widget.dart
- widgets/editor/template_upload_widget.dart

## features/templates/presentation/screens/templates_screen.dart
- ../../../core/services/category_management_service.dart
- ../../../core/services/template_creation_service.dart
- ../../../data/providers/state/app_state_provider.dart
- ../../../shared/navigation/template_navigation_handler.dart
- ../../../shared/state/templates_screen_state.dart
- ../../../shared/widgets/common/error_snackbar.dart
- widgets/dialogs/email_template_editor.dart
- widgets/dialogs/field_dialog.dart
- widgets/dialogs/message_template_editor.dart
- widgets/tabs/email_templates_tab.dart
- widgets/tabs/fields_tab.dart
- widgets/tabs/message_templates_tab.dart
- widgets/tabs/pdf_templates_tab.dart
- widgets/tabs/template_app_bar.dart
- widgets/template_fab_manager.dart

## features/templates/presentation/widgets/dialogs/category_creation_dialog.dart
- ../../../../app/theme/rufko_theme.dart

## features/templates/presentation/widgets/dialogs/category_selection_dialog.dart
- ../../../../app/theme/rufko_theme.dart
- ../../../../data/providers/state/app_state_provider.dart
- category_creation_dialog.dart

## features/templates/presentation/widgets/dialogs/email_template_editor.dart
- ../../../../data/models/templates/email_template.dart
- ../../../../data/providers/state/app_state_provider.dart

## features/templates/presentation/widgets/dialogs/field_dialog.dart
- ../../../../app/theme/rufko_theme.dart
- ../../../../core/mixins/field_type_mixin.dart
- ../../../../data/models/settings/custom_app_data.dart
- ../../../../data/providers/state/app_state_provider.dart

## features/templates/presentation/widgets/dialogs/message_template_editor.dart
- ../../../../data/models/templates/message_template.dart
- ../../../../data/providers/state/app_state_provider.dart

## features/templates/presentation/widgets/editor/field_mapping_bottom_sheet.dart
- ../../../../core/utils/helpers/pdf_field_utils.dart
- ../../../../data/models/templates/pdf_template.dart

## features/templates/presentation/widgets/editor/field_selection_dialog.dart
- ../../../../app/theme/rufko_theme.dart
- ../../../../data/models/business/product.dart
- ../../../../data/models/templates/pdf_template.dart
- ../../../../shared/widgets/common/field_category_list.dart

## features/templates/presentation/widgets/tabs/email_templates_tab.dart
- ../../../../core/mixins/template_tab_mixin.dart
- ../../../../data/models/templates/email_template.dart
- ../../../../data/providers/state/app_state_provider.dart
- dialogs/email_template_editor.dart

## features/templates/presentation/widgets/tabs/fields_tab.dart
- ../../../../app/theme/rufko_theme.dart
- ../../../../core/mixins/template_tab_mixin.dart
- ../../../../core/utils/helpers/common_utils.dart
- ../../../../data/models/settings/custom_app_data.dart
- ../../../../data/providers/state/app_state_provider.dart
- dialogs/field_dialog.dart

## features/templates/presentation/widgets/tabs/message_templates_tab.dart
- ../../../../core/mixins/template_tab_mixin.dart
- ../../../../data/models/templates/message_template.dart
- ../../../../data/providers/state/app_state_provider.dart
- dialogs/message_template_editor.dart

## features/templates/presentation/widgets/tabs/pdf_templates_tab.dart
- ../../../../app/theme/rufko_theme.dart
- ../../../../core/mixins/template_tab_mixin.dart
- ../../../../data/models/templates/pdf_template.dart
- ../../../../data/providers/state/app_state_provider.dart
- ../../../quotes/presentation/screens/pdf_preview_screen.dart
- ../screens/template_editor_screen.dart

## features/templates/presentation/widgets/tabs/template_app_bar.dart
- ../../../../app/theme/rufko_theme.dart

## features/templates/presentation/widgets/template_fab_manager.dart
- ../../../app/theme/rufko_theme.dart

## main.dart
- app/theme/rufko_theme.dart
- core/services/database/database_service.dart
- core/services/external/tax_service.dart
- data/models/business/customer.dart
- data/models/business/product.dart
- data/models/business/quote.dart
- data/models/business/roof_scope_data.dart
- data/models/business/simplified_quote.dart
- data/models/media/inspection_document.dart
- data/models/media/project_media.dart
- data/models/settings/app_settings.dart
- data/models/settings/custom_app_data.dart
- data/models/templates/email_template.dart
- data/models/templates/message_template.dart
- data/models/templates/pdf_template.dart
- data/models/templates/template_category.dart
- data/providers/customer_provider.dart
- data/providers/product_provider.dart
- data/providers/quote_provider.dart
- data/providers/state/app_state_provider.dart
- data/providers/template_provider.dart
- features/dashboard/presentation/screens/home_screen.dart

## shared/controllers/navigation_controller.dart
- ../data/models/business/customer.dart
- ../data/models/business/simplified_quote.dart
- ../features/quotes/presentation/screens/simplified_quote_detail_screen.dart
- ../features/quotes/presentation/screens/simplified_quote_screen.dart

## shared/controllers/ui_state_controller.dart
- ../app/theme/rufko_theme.dart
- ../data/providers/state/app_state_provider.dart

## shared/navigation/template_navigation_handler.dart
- ../features/templates/presentation/screens/category_management_screen.dart
- ../features/templates/presentation/screens/template_editor_screen.dart

## shared/state/field_mapping_state.dart
- ../data/models/templates/pdf_template.dart

## shared/state/template_editor_state.dart
- ../data/models/templates/pdf_template.dart

## shared/widgets/common/field_category_list.dart
- ../../core/utils/helpers/pdf_field_utils.dart
- ../../data/models/business/product.dart
- ../../data/models/templates/pdf_template.dart
- ../../data/models/ui/field_definition.dart

## shared/widgets/dialogs/help_dialog.dart
- ../../core/utils/settings_constants.dart

## shared/widgets/dialogs/premium_feature_dialog.dart
- ../../core/utils/settings_constants.dart

