import * as path from 'path';
import * as Mocha from 'mocha';
import * as glob from 'glob';


export function run(testsRoot: string, callback: (error: any, failures?: number) => void): void {
  const mocha = new Mocha({
    ui: 'bdd',
    timeout: 600000,
    color: true,
  });

  glob('**/**.test.js', { cwd: testsRoot }, (error, files) => {
    if (error) {
      return callback(error);
    }

    files.forEach(file => mocha.addFile(path.resolve(testsRoot, file)));

    try {
      mocha.run(failures => callback(null, failures))
    } catch (error) {
      callback(error)
    }
  });
}
