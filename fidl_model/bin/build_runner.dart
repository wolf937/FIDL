// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import 'package:build_runner/src/build_script_generate/bootstrap.dart';
import 'package:build_runner/src/entrypoint/runner.dart';
import 'package:build_runner/src/logging/std_io_logging.dart';

import 'commands/clean.dart';
import 'commands/generate_build_script.dart';

Future<void> run(List<String> args) async {
  // Use the actual command runner to parse the args and immediately print the
  // usage information if there is no command provided or the help command was
  // explicitly invoked.
  var commandRunner = BuildCommandRunner([]);
  var localCommands = [CleanCommand(), GenerateBuildScript()];
  var localCommandNames = localCommands.map((c) => c.name).toSet();
  localCommands.forEach(commandRunner.addCommand);

  ArgResults parsedArgs;
  try {
    parsedArgs = commandRunner.parse(args);
  } on UsageException catch (e) {
    print(red.wrap(e.message));
    print('');
    print(e.usage);
    exitCode = ExitCode.usage.code;
    return;
  }

  var commandName = parsedArgs.command?.name;

  if (parsedArgs.rest.isNotEmpty) {
    print(
        yellow.wrap('Could not find a command named "${parsedArgs.rest[0]}".'));
    print('');
    print(commandRunner.usageWithoutDescription);
    exitCode = ExitCode.usage.code;
    return;
  }

  if (commandName == null || commandName == 'help') {
    commandRunner.printUsage();
    return;
  }

  final logListener = Logger.root.onRecord.listen(stdIOLogListener());
  if (localCommandNames.contains(commandName)) {
    exitCode = await commandRunner.runCommand(parsedArgs);
  } else {
    while ((exitCode = await generateAndRun(args)) == ExitCode.tempFail.code) {}
  }
  await logListener?.cancel();
}
