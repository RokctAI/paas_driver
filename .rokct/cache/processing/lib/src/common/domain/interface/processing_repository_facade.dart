// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:base_sdk/base_sdk.dart';

/// Consumer-owned persistence/transport boundary for the engine.
///
/// The host app decides where contract state lives (backend endpoint, local
/// database, or both) and registers an implementation via
/// ProcessingSdkDependencies.register. A local offline implementation
/// backed by base_sdk's shared database ships with this SDK.
abstract class ProcessingRepositoryFacade {
  Future<ApiResult<List<ProcessingContract>>> getContracts({String? type});

  Future<ApiResult<ProcessingContract?>> getContract(String contractId);

  Future<ApiResult<ProcessingContract>> saveContract(
    ProcessingContract contract,
  );

  Future<ApiResult<void>> deleteContract(String contractId);
}
