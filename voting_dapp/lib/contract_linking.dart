import 'dart:convert';
import 'package:flutter/material.dart';  // For BuildContext
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class ContractLinking {
  late Web3Client ethClient;
  late DeployedContract contract;
  late ContractFunction voteFunction;
  late ContractFunction getCandidateCount;
  late ContractFunction getCandidate;

  final String rpcUrl = "https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID";
  final String contractAddress = "YOUR_DEPLOYED_CONTRACT_ADDRESS";

  ReownAppKitModal? appKitModal;  // New service class
  String? account;

  ContractLinking() {
    ethClient = Web3Client(rpcUrl, Client());
    init();
  }

  Future<void> init() async {
    String abi = await rootBundle.loadString('assets/abi.json');
    contract = DeployedContract(
      ContractAbi.fromJson(abi, 'Voting'),
      EthereumAddress.fromHex(contractAddress),
    );

    voteFunction = contract.function('vote');
    getCandidateCount = contract.function('getCandidateCount');
    getCandidate = contract.function('getCandidate');
  }

  Future<void> connectWallet(BuildContext context) async {
    appKitModal = ReownAppKitModal(
      context: context,  // Required for modal overlay
      projectId: 'YOUR_PROJECT_ID_FROM_CLOUD.REOWN.COM',
      metadata: const PairingMetadata(
        name: 'Voting DApp',
        description: 'Simple Web3 Voting',
        url: 'https://example.com',
        icons: ['https://example.com/icon.png'],
      ),
      // Optional: Specify chains (Sepolia + others if needed)
      // recommendedChains: [ReownAppKitModalNetworks.eip155_11155111],
    );

    await appKitModal!.init();

    // Connection event
    appKitModal!.onModalConnect.subscribe((ModalConnect? event) {
      if (event != null && event.session != null) {
        final namespaces = event.session.namespaces;
        final eip155Accounts = namespaces?['eip155']?.accounts ?? [];
        if (eip155Accounts.isNotEmpty) {
          final addressParts = eip155Accounts.first.split(':');
          if (addressParts.length == 3) {
            account = addressParts[2];
            // Update UI (setState or notifyListeners)
          }
        }
      }
    });

    // Disconnect event
    appKitModal!.onModalDisconnect.subscribe((_) {
      account = null;
      // Update UI
    });

    // Open the modal
    appKitModal!.openModalView();
  }

  Future<List> getCandidates() async {
    final count = await ethClient.call(
      contract: contract,
      function: getCandidateCount,
      params: [],
    ) as BigInt;

    List candidates = [];
    for (var i = 0; i < count.toInt(); i++) {
      final cand = await ethClient.call(
        contract: contract,
        function: getCandidate,
        params: [BigInt.from(i)],
      );
      candidates.add({'name': cand[0], 'votes': cand[1].toInt()});
    }
    return candidates;
  }

  Future<String> vote(int index) async {
    if (account == null || appKitModal?.session == null) {
      throw Exception("Wallet not connected");
    }

    // Encode the function call data
    final data = voteFunction.encodeCall([BigInt.from(index)]);

    // Send transaction via wallet (no private key needed!)
    final txHash = await appKitModal!.request(
      topic: appKitModal!.session!.topic,
      chainId: 'eip155:11155111',  // Sepolia
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [
          {
            'from': account,
            'to': contractAddress,
            'data': '0x${bytesToHex(data, include0x: true)}',
            // Optional: gas, value, etc.
          }
        ],
      ),
    );

    return txHash as String;  // Returns transaction hash
  }
}