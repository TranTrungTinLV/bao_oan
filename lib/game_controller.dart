/// Game state management for BÁO OAN demo
/// Quản lý scene hiện tại, inventory, flags sự kiện

enum GameScene {
  outside,    // Ngoài nhà trọ 403
  inside,     // Bên trong tầng trệt
  attic,      // Gác mái
  endDemo,    // Kết thúc demo
}

class GameController {
  GameScene currentScene = GameScene.outside;
  
  // Dialog state
  int dialogIndex = 0;
  bool isDialogActive = false;
  String currentSpeaker = '';
  
  // Game flags
  bool metBaHuyen = false;
  bool gotKey = false;
  bool enteredHouse = false;
  bool metBaNam = false;
  bool heardNoise = false;
  bool wentToAttic = false;
  bool foundDiary = false;
  
  // Player position
  double playerX = 0.15;
  bool playerFacingRight = true;
  
  // NPC positions
  double baHuyenX = 0.68;
  double baNamX = 0.7;
  
  // Interaction zones
  bool isNearDoor() => playerX > 0.4 && playerX < 0.6 && currentScene == GameScene.outside;
  bool isNearSofa() => playerX < 0.35 && currentScene == GameScene.inside;
  bool isNearStairs() => playerX > 0.65 && currentScene == GameScene.inside;
  bool isNearDiary() => playerX > 0.4 && playerX < 0.7 && currentScene == GameScene.attic;
  bool isNearBaHuyen() => (playerX - baHuyenX).abs() < 0.15 && currentScene == GameScene.outside;
  bool isNearBaNam() => (playerX - baNamX).abs() < 0.15 && currentScene == GameScene.inside;
  
  // Dialog data theo cốt truyện
  List<DialogLine> getDialogsForScene() {
    switch (currentScene) {
      case GameScene.outside:
        if (!metBaHuyen) {
          return [
            DialogLine('Bà Huyền', 'Cậu trai này kiếm ai thế?', true),
            DialogLine('Kiên', 'Cháu tới thuê trọ cô ạ, vừa mới tìm được đến đây mà mưa quá.', false),
            DialogLine('Bà Huyền', 'Thuê trọ à?! Thế cháu có phải là con của ông Nhân không?!', true),
            DialogLine('Kiên', 'Vâng đúng rồi cô ạ!', false),
            DialogLine('Bà Huyền', 'Tưởng đâu là ai cứ đứng lấp ló. Cô có nghe ba cháu nói qua rồi, cháu chờ một chút cô vào lấy chìa khoá.', true),
            DialogLine('Hệ thống', '🔑 Bạn đã nhận được chìa khóa phòng 403.', false),
          ];
        }
        return [];
      case GameScene.inside:
        if (!metBaNam && enteredHouse) {
          return [
            DialogLine('Bà Năm', 'Cậu mới chuyển đến à?', true),
            DialogLine('Kiên', 'Dạ vâng cháu mới chuyển đến hồi tối hôm qua.', false),
            DialogLine('Bà Năm', 'Thế... cậu có cúng kiến gì khi vào ở chưa?', true),
            DialogLine('Kiên', 'Cúng kiến? Cúng kiến gì hả bà?', false),
            DialogLine('Bà Năm', 'Người mới dọn vào thì ít nhất cũng phải cúng kiến xin những người khuất mặt khuất mày ở đây. Cậu cẩn thận đấy!', true),
            DialogLine('Kiên', 'Mấy cái chuyện mê tín như thế này cháu không tin đâu ạ!', false),
          ];
        }
        if (heardNoise && !wentToAttic) {
          return [
            DialogLine('Kiên', 'Quái lạ, tiếng động gì ở trên gác vậy? Chắc là lũ chuột...', false),
            DialogLine('Hệ thống', '⬆️ Hãy đi lên cầu thang để kiểm tra gác mái.', false),
          ];
        }
        return [];
      case GameScene.attic:
        if (!foundDiary) {
          return [
            DialogLine('Kiên', 'Không có con chuột nào cả... Nhưng chờ đã, cuốn nhật ký này...', false),
            DialogLine('Kiên', 'Nó đang mở sẵn?! Rõ ràng mình đã cất nó đi rồi mà!', false),
            DialogLine('Hệ thống', '📓 Bạn đã tìm thấy cuốn nhật ký bí ẩn...', false),
          ];
        }
        return [];
      case GameScene.endDemo:
        return [];
    }
  }
  
  void resetDialogIndex() {
    dialogIndex = 0;
  }
}

class DialogLine {
  final String speaker;
  final String text;
  final bool isNPC; // true = NPC, false = player/system
  
  DialogLine(this.speaker, this.text, this.isNPC);
}
