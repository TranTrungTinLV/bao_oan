import 'package:flutter/material.dart';

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
  bool wentToSleep = false; // Tự động đi ngủ ngày 1
  bool morningArrived = false; // Sáng hôm sau ngày 2
  bool foundOldItems = false; // Tìm thấy Thẻ sinh viên & Đồng hồ cũ
  bool heardNoise1 = false; // Lần 1 nghe tiếng động
  bool visitedAtticFirstTime = false; // Lên gác kiếm chuột lần đầu
  bool heardNoise2 = false; // Lần 2 nghe tiếng động dồn dập
  bool wentToAttic = false; // Lên gác lần 2
  bool foundDiary = false;
  
  // Horror flags
  double sanityLevel = 1.0; // 1.0 (Bình thường), giảm dần khi gặp ma
  bool isPowerOff = false; // Tắt đèn lúc 3:15 sáng
  bool lookedInMirror = false; // Đã soi gương trong nhà vệ sinh chưa
  bool solvedMandala = false; // Giải đố Mạn-đà-la 5 góc
  bool solvedTornPaper = false; // Giải đố Ráp bùa rách
  bool solvedBetelTray = false; // Giải đố Khay trầu cau (hiện chữ máu)
  bool solvedOffering = false; // Nghi thức cúng cô hồn
  bool solvedDiaryDecode = false; // Giải mã nhật ký
  bool solvedGhostRiddle = false; // Câu đố ma dân gian
  bool solvedKhmerCharm = false; // Bùa ngãi Khơ Me

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
  bool isNearMirror() => playerX > 0.4 && playerX < 0.55 && currentScene == GameScene.inside; // Nhà vệ sinh tạm ở giữa nhà
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
        if (!wentToSleep && enteredHouse) {
          return [
            DialogLine('Kiên', 'Dọn dẹp mệt quá... Căn nhà này cũng không bề bộn lắm.', false),
            DialogLine('Kiên', 'Có sẵn cái ghế Sofa cũ, mình nằm chợp mắt một chút vậy...', false),
            DialogLine('Hệ thống', 'Tiếng mưa rơi rả rít ngoài hiên, gió cứ ào ào thổi vào... Kiên nhanh chóng chìm vào giấc ngủ.', false),
          ];
        }
        if (wentToSleep && isPowerOff && !lookedInMirror) {
          return [
            DialogLine('Kiên', 'Trời đụ má... mấy giờ rồi nhỉ? Điện thoại bảo 3:15 AM?', false),
            DialogLine('Kiên', 'Ơ cúp điện à? Sao lại đúng lúc thế này chứ!!!', false),
            DialogLine('Kiên', 'Khoan đã... tiếng kèn trống đám tang ở đâu vọng lại thế này? Nửa đêm rồi cơ mà?', false),
            DialogLine('Hệ thống', '💡 Nhấn bật đèn pin. Đi xuống nhà tìm bồn rửa mặt soi gương xem sao.', false),
          ];
        }
        if (lookedInMirror && !morningArrived) {
          return [
            DialogLine('Kiên', 'Con cặc gì trong gương vừa nãy vậy...', false),
            DialogLine('Kiên', 'Cố nhắm mắt đến sáng... Trưa rồi, mình đem rác đi vứt thôi.', false),
            DialogLine('Hệ thống', 'Bạn kéo bọc rác ra ngoài cửa...', false),
          ];
        }
        if (morningArrived && !metBaNam) {
          return [
            DialogLine('Bà Năm', 'Cậu mới chuyển đến à?', true),
            DialogLine('Kiên', 'Dạ vâng cháu mới chuyển đến hồi tối hôm qua.', false),
            DialogLine('Bà Năm', 'Thế... cậu có cúng kiến gì khi vào ở chưa?', true),
            DialogLine('Kiên', 'Cúng kiến? Cúng kiến gì hả bà?', false),
            DialogLine('Bà Năm', 'Người dọn vào thì ít nhất cũng phải cúng xin những người khuất mặt khuất mày. Cậu cẩn thận đấy!', true),
            DialogLine('Kiên', 'Con cặc...', false, choices: [
              DialogChoice('Mấy cái chuyện mê tín này cháu không tin đâu!', () {
                sanityLevel -= 0.1; // Cứng đầu thì bị ám mạnh hơn
              }),
              DialogChoice('Cháu mới tới chưa rành, bà chỉ cháu với.', () {
                sanityLevel += 0.1;
              }),
            ]),
            DialogLine('Bà Năm', 'Nhớ kỹ mảnh giấy tôi đưa. Lỡ có chuyện gì không lành thì nhớ nhẩm: Mệnh Hỏa chỉ Đỏ, Thổ Đen, Kim Xám, Thủy Đen, Mộc Đỏ... (Đỏ - Đen - Xám - Đen - Đỏ)', true),
          ];
        }
        if (foundOldItems && !heardNoise1) {
          return [
            DialogLine('Kiên', 'Chỗ này có mớ đồ cũ của ai để quên từ trước nhỉ...', false),
            DialogLine('Hệ thống', 'Bạn tìm thấy 1 cái Đồng hồ, 1 Thẻ Sinh Viên chữ bị phai mờ, và 1 cuốn Nhật Ký dính chặt vào nhau.', false),
            DialogLine('Kiên', 'Chắc của sinh viên nào thuê trước đây bỏ lại. Thôi cứ cất gọn vào vậy.', false),
          ];
        }
        if (heardNoise1 && !visitedAtticFirstTime) {
          return [
            DialogLine('Kiên', 'Quái lạ, tiếng động loạt soạt gì ở trên gác vậy? Chắc là lũ chuột...', false),
            DialogLine('Hệ thống', '⬆️ Hãy đi lên cầu thang để kiểm tra gác mái lần 1.', false),
          ];
        }
        if (heardNoise2 && !wentToAttic) {
          return [
            DialogLine('Kiên', 'Lại nữa?! Lần này tiếng động dồn dập hơn lúc nãy! Không thể nào là chuột được!', false),
            DialogLine('Hệ thống', '⬆️ Hãy lên cầu thang kiểm tra lần 2.', false),
          ];
        }
        if (solvedTornPaper && !solvedBetelTray) {
          return [
            DialogLine('Kiên', 'Lá bùa rách đã bị đốt cháy... Mình cảm thấy luồng khí lạnh đang tập trung ở chỗ chiếc Ghế Sofa.', false),
            DialogLine('Hệ thống', 'Mùi máu tanh từ khay trầu cau... Hãy đi tới Ghế Sofa kiểm tra!', false),
          ];
        }
        return [];
      case GameScene.attic:
        if (visitedAtticFirstTime && !heardNoise2) {
          return [
            DialogLine('Kiên', 'Đèn sáng trưng thế này! Quái lạ, không có dấu vết của con chuột nào! Vết ố vàng gì đây?', false),
            DialogLine('Hệ thống', 'Bạn phát hiện nhiều vệt ố vàng lạ trên bức tường trắng.', false),
            DialogLine('Kiên', 'Lúc nãy đi xem phòng nào có thấy đâu... Chắc hoa mắt do thiếu ngủ. Thôi xuống Sofa nằm ngủ tiếp.', false),
          ];
        }
        if (wentToAttic && !foundDiary) {
          return [
            DialogLine('Kiên', 'Nhật ký?! Nó đang mở sẵn ở trên giường kìa?! Rõ ràng mình cất nó ở dưới nhà rồi cơ mà!', false),
            DialogLine('Kiên', 'Nhớ lại lời Bà Năm dặn khi nãy... Đỏ, Đen, Xám...', false),
            DialogLine('Hệ thống', '📓 Tương tác vào các vòng chỉ để mở khóa nhật ký.', false),
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

class DialogChoice {
  final String text;
  final VoidCallback onSelected;
  DialogChoice(this.text, this.onSelected);
}

class DialogLine {
  final String speaker;
  final String text;
  final bool isNPC; // true = NPC, false = player/system
  final List<DialogChoice>? choices; // Nullable choices
  
  DialogLine(this.speaker, this.text, this.isNPC, {this.choices});
}
