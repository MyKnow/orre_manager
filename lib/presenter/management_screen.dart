import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orre_manager/Model/store_data_model.dart';
import 'package:orre_manager/presenter/Widget/ManagerPage/MenuList.dart';
import 'package:orre_manager/presenter/table_status_screen.dart';
import 'package:orre_manager/provider/DataProvider/stomp_client_future_provider.dart';
import 'package:orre_manager/provider/DataProvider/store_data_provider.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../Model/login_data_model.dart';
import '../Model/waiting_data_model.dart';
import '../provider/DataProvider/waiting_provider.dart';

class ManagementScreenWidget extends ConsumerWidget {
  final LoginData loginResponse;
  ManagementScreenWidget({required this.loginResponse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stompClientAsyncValue = ref.watch(stompClientProvider);

    return stompClientAsyncValue.when(
      data: (stompClient) {
        return ManagementScreenBody(loginData: loginResponse);
      },
      loading: () {
        // 로딩 중이면 로딩 스피너를 표시합니다.
        return _LoadingScreen();
      },
      error: (error, stackTrace) {
        // 에러가 발생하면 에러 메시지를 표시합니다.
        return _ErrorScreen(error);
      },
    );
  }
}

class ManagementScreenBody extends ConsumerStatefulWidget {
  final LoginData loginData;

  ManagementScreenBody({required this.loginData});

  @override
  _ManagementScreenBodyState createState() => _ManagementScreenBodyState();
}

class _ManagementScreenBodyState extends ConsumerState<ManagementScreenBody> {
  StoreData? currentStoreData;
  bool isSubscribed = false;

  @override
  void initState() {
    super.initState();
    // 데이터 요청 로직을 initState로 이동하여 최초 1회만 실행
    ref.read(storeDataProvider.notifier).requestStoreData(widget.loginData.storeCode);
  }

  @override
  Widget build(BuildContext context) {
    currentStoreData = ref.watch(storeDataProvider);

    if (currentStoreData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('가게 관리 화면')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('매장 코드 : ${widget.loginData.storeCode}', style: TextStyle(fontSize: 20)),
              ElevatedButton(
                onPressed: () {}, // 데이터는 이미 요청됨
                child: Text("가게 정보 수신하기"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('가게 정보 관리 화면')),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: currentStoreData!.storeImageMain.isNotEmpty
                ? SizedBox(
                    width: 200,
                    height: 200,
                    child: Image.network(currentStoreData!.storeImageMain, fit: BoxFit.cover),
                  )
                : SizedBox.shrink(),
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(currentStoreData!.storeName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  buildTimeRow('영업시간', currentStoreData!.openingTime, currentStoreData!.closingTime, () {
                    // 영업시간 수정 로직
                  }),
                  buildTimeRow('라스트오더', currentStoreData!.lastOrderTime, '', () {
                    // 라스트오더 수정 로직
                  }),
                  buildTimeRow('브레이크타임', currentStoreData!.startBreakTime, currentStoreData!.endBreakTime, () {
                    // 브레이크타임 수정 로직
                  }),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (BuildContext context) => MenuListWidget(loginResponse: widget.loginData)
                      ));
                    },
                    child: Text('메뉴 관리하기'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(storeDataProvider.notifier).requestStoreData(widget.loginData.storeCode);
                    },
                    child: Text('새로고침'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTimeRow(String label, String time1, String time2, VoidCallback onPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label: $time1 ${time2.isNotEmpty ? '~ $time2' : ''}', style: TextStyle(fontSize: 18)),
        TextButton(
          onPressed: onPressed,
          child: Text('$label 수정하기'),
        ),
      ],
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('가게관리페이지'),
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final dynamic error;

  _ErrorScreen(this.error);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Store Page'),
      ),
      body: Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

