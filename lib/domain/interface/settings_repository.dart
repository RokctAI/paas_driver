import '../../infrastructure/models/models.dart';
import '../../infrastructure/services/services.dart';
import '../handlers/handlers.dart';

abstract class SettingsRepository {
  Future<ApiResult<GalleryUploadResponse>> uploadImage(
    String filePath,
    UploadType uploadType,
  );

  Future<ApiResult<CurrenciesResponse>> getCurrencies();

  Future<ApiResult<SettingsResponse>> getGlobalSettings();

  Future<ApiResult<TranslationsResponse>> getTranslations();

  Future<ApiResult<LanguagesResponse>> getLanguages();
}
